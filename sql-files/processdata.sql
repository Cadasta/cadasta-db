--  Trigger to process FormHub data.json file after loading
CREATE OR REPLACE FUNCTION cd_process_data()
RETURNS TRIGGER AS $cd_process_data$
DECLARE
  raw_data_id integer;
  survey record;
  element record;
  options record;
  option record;
  data_respondent_id integer;
  data_person_id int;
  data_geom_type character varying;
  question_id integer;
  question_id_l integer;
  data_relationship_id int;
  data_date_land_possession date;
  data_means_aquired character varying;
  data_survey_id integer;
  data_tenure_type character varying;
  data_parcel_id int;
  data_survey_first_name character varying;
  data_survey_last_name character varying;
  question_slug text;
  parent_question_slug text;
  data_ckan_user_id int;
  numeric_value numeric;
  num_slugs integer;
  num_questions integer;
  count integer;
  question_type text;
  point text;
  x numeric;
  y numeric;
BEGIN
  -- get the ID from the new record
  raw_data_id := NEW.id;
  count := 0;
    RAISE NOTICE 'Processing Data..... %', raw_data_id;

  -- loop through each survey in the json object
  FOR survey IN (SELECT * FROM json_array_elements((select json from raw_data where id = raw_data_id))) LOOP

    -- get the survey id
    SELECT INTO data_survey_id id FROM survey WHERE id_string = (SELECT value::text FROM json_each_text(survey.value) WHERE key = '_xform_id_string');
    -- get ckan user id
    SELECT INTO data_ckan_user_id id from survey where id = data_survey_id;
    -- get respondent first name
    SELECT INTO data_survey_first_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_first';
    -- get respondent last name
    SELECT INTO data_survey_last_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_last';

    -- process survey data only if there is a survey in the database that matches
    IF data_survey_id IS NOT NULL THEN
        -- take the first name , last name fields out of the survey
        SELECT INTO data_person_id * FROM cd_create_person (data_survey_first_name,data_survey_last_name);

        RAISE NOTICE 'Created Person id: %', data_person_id;

      EXECUTE 'INSERT INTO respondent (survey_id, time_created) VALUES ('|| data_survey_id || ',' || quote_literal(current_timestamp) || ') RETURNING id' INTO data_respondent_id;

      -- add person_id to respondent
      UPDATE respondent SET person_id = data_person_id WHERE id = data_respondent_id;

      count := count + 1;
      RAISE NOTICE 'Processing survey number % ...', count;
      FOR element IN (SELECT * FROM json_each_text(survey.value)) LOOP
      IF (element.key IS NOT NULL) THEN

        SELECT INTO question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1) as slugs;
        SELECT INTO num_slugs count(slugs) FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum) as slugs;
        SELECT INTO num_questions count(id) FROM question WHERE lower(name) = lower(question_slug) AND survey_id = data_survey_id;
	-- get question id
        SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND survey_id = data_survey_id;
        IF num_questions > 1 THEN
          RAISE NOTICE '---------> MULTIPLE QUESTIONS FOUND!!!: %', num_questions || ' (count) key: ' || element.key || ' question_id found: ' || question_id;
          IF num_slugs > 1 THEN
            SELECT INTO parent_question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1 offset 1) as slugs;
            -- get question id
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND survey_id = data_survey_id AND group_id = (select id from "group" where lower(name) = lower(parent_question_slug));
          ELSE
            -- get question id
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND survey_id = data_survey_id AND group_id IS NULL;
          END IF;
          RAISE NOTICE '---------> QUESTION ID UPDATED: %', question_id;
        END IF;

        CASE (element.key)
          WHEN 'means_of_acquire' THEN
            data_means_aquired = element.value;
          WHEN 'date_land_possession' THEN
            data_date_land_possession = element.value;
          WHEN 'proprietorship' THEN
            CASE (element.value)
              WHEN 'allodial' THEN
                data_tenure_type = 'Own';
              WHEN 'freehold' THEN
                data_tenure_type = 'Own';
              WHEN 'lease' THEN
                data_tenure_type = 'Lease';
              ELSE
                RAISE NOTICE 'Improper Tenure Type';
            END CASE;
            RAISE NOTICE 'Found Loan';
          ELSE
            RAISE NOTICE 'Cannot Find Loan';
        END CASE;

        RAISE NOTICE 'Data tenture type: %', data_tenure_type;

        -- RAISE NOTICE 'Element: %', element.key;
        -- RAISE NOTICE 'Last slug: %', question_slug;
        IF (question_id IS NOT NULL) THEN
          SELECT INTO question_type name FROM type WHERE id = (SELECT type_id FROM question WHERE id = question_id);
          -- RAISE NOTICE 'Found question: %', question_id || ' - ' || question_type;
          -- check to see if this is a loop (group or repeat type)
          CASE (question_type)
            WHEN 'integer','decimal' THEN
              IF is_numeric(element.value) THEN
                numeric_value := element.value;
                IF numeric_value >= 0 THEN
                  EXECUTE 'INSERT INTO response (respondent_id, question_id, numeric) VALUES (' || data_respondent_id || ','
			|| question_id || ',' ||  element.value || ');';
                ELSE
                  EXECUTE 'INSERT INTO response (respondent_id, question_id, numeric) VALUES (' || data_respondent_id || ','
	  		|| question_id || ', NULL);';
                END IF;
	      END IF;
            ELSE
                EXECUTE 'INSERT INTO response (respondent_id, question_id, text) VALUES (' || data_respondent_id || ','
	  		|| question_id || ',' || quote_literal(element.value) ||');';
          END CASE;
        -- question is not found in the database
        ELSE
        -- RAISE NOTICE 'Cant find question: %', element.key;
          -- elements that have a key starting with an underscore, are not a survey question EXCEPT _geolocation
          IF left(element.key, 1) = '_' THEN
            CASE (lower(element.key))
              WHEN ('_id') THEN
                EXECUTE 'UPDATE respondent SET id_string = ' || quote_literal(element.value) || ' WHERE id = ' || data_respondent_id;
              WHEN ('_geolocation') THEN
                SELECT INTO point regexp_replace(element.value, '"|,|\[|\]', '', 'g');
                -- RAISE NOTICE 'point: %', point;
                x := substring(point, 0, position(' ' in point))::numeric;
                y := substring(point, (position(' ' in point)+1), char_length(point))::numeric;
                -- RAISE NOTICE 'x: %', x;
                -- RAISE NOTICE 'y: %', y;
                IF point IS NOT NULL AND point <> 'null null' THEN

                  -- Geom type is point
                  data_geom_type = 'Point';

                  -- Create new parcel with lat lng as geometry
                  SELECT INTO data_parcel_id * FROM cd_create_parcel ('survey_grade_gps',data_ckan_user_id,null,data_geom_type,null,y,x,null,null,'new description');
                  RAISE NOTICE 'New parcel id: %', data_parcel_id;

                  -- set new parcel id in survey table
                  UPDATE survey SET parcel_id = data_parcel_id WHERE id = data_survey_id;
                  RAISE NOTICE 'Updated survey set parcel_id = %', data_parcel_id;
                ELSE
                  -- create parcel with no geometry
                  -- edit cd_create_parcel to create parcels without geom
                END IF;
              WHEN ('_submission_time') THEN
                IF element.value IS NOT NULL THEN
                  EXECUTE 'UPDATE respondent SET submission_time = ' || quote_literal(replace(element.value,'T',' ')) || ' WHERE id = ' || data_respondent_id;
                END IF;
              ELSE
            END CASE;
          END IF;
        END IF;
      END IF;
    END LOOP;
      IF data_survey_id IS NOT NULL THEN
        EXECUTE 'UPDATE response SET survey_id = ' || quote_literal(data_survey_id) || ' WHERE respondent_id = ' || data_respondent_id;
      END IF;
      IF data_parcel_id IS NOT NULL AND data_person_id IS NOT NULL THEN
        -- create relationship

        SELECT INTO data_relationship_id * FROM cd_create_relationship
        (data_parcel_id,data_ckan_user_id,data_person_id,null,null,data_tenure_type,data_date_land_possession, data_means_aquired, false, null);

        IF data_relationship_id IS NOT NULL THEN
            RAISE NOTICE 'New relationship id: %', data_relationship_id;
        ELSE
            RAISE NOTICE 'No new relationship';
        END IF;
      END IF;
    END IF;
  END LOOP;
  RETURN NEW;
END;
$cd_process_data$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS cd_process_data ON raw_data;
CREATE TRIGGER cd_process_data AFTER INSERT ON raw_data
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();