--  Trigger to process FormHub data.json file after loading
CREATE OR REPLACE FUNCTION cd_process_data()
RETURNS TRIGGER AS $cd_process_data$
DECLARE
  raw_data_id integer;
  raw_field_data_id integer;
  raw_group_id integer;
  survey record;
  element record;
  options record;
  option record;
  data_respondent_id integer;
  data_person_id int;
  data_geom geometry;
  question_id integer;
  question_id_l integer;
  data_relationship_id int;
  data_date_land_possession date;
  data_geojson character varying;
  data_means_aquired character varying;
  data_survey_id integer;
  data_tenure_type character varying;
  tenure_type_id int;
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
  raw_field_data_id = NEW.field_data_id;
  data_ckan_user_id = 11;

  count := 0;
    RAISE NOTICE 'Processing Data..... %', raw_data_id;

  -- loop through each survey in the json object
  FOR survey IN (SELECT * FROM json_array_elements((select json from raw_data where id = raw_data_id))) LOOP

    -- get the survey id
    -- SELECT INTO data_survey_id id FROM survey WHERE id_string = (SELECT value::text FROM json_each_text(survey.value) WHERE key = '_xform_id_string');

    data_survey_id = raw_field_data_id;

    IF data_survey_id IS NOT NULL THEN

    -- get respondent first name
    SELECT INTO data_survey_first_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_first';
    -- get respondent last name
    SELECT INTO data_survey_last_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_last';

    -- process survey data only if there is a survey in the database that matches
    IF raw_field_data_id IS NOT NULL THEN

        -- take the first name , last name fields out of the survey
        IF data_survey_first_name IS NOT NULL AND data_survey_last_name IS NOT NULL THEN
          SELECT INTO data_person_id * FROM cd_create_party (data_survey_first_name,data_survey_last_name);
          RAISE NOTICE 'Created Person id: %', data_person_id;
        END IF;

      EXECUTE 'INSERT INTO respondent (field_data_id, time_created) VALUES ('|| raw_field_data_id || ',' || quote_literal(current_timestamp) || ') RETURNING id' INTO data_respondent_id;

      count := count + 1;
      RAISE NOTICE 'Processing survey number % ...', count;
      FOR element IN (SELECT * FROM json_each_text(survey.value)) LOOP
      IF (element.key IS NOT NULL) THEN

        SELECT INTO question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1) as slugs;
        SELECT INTO num_slugs count(slugs) FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum) as slugs;
        SELECT INTO num_questions count(id) FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = raw_field_data_id;
	-- get question id
        SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = raw_field_data_id;

        IF num_questions > 1 THEN
          RAISE NOTICE '---------> MULTIPLE QUESTIONS FOUND!!!: %', num_questions || ' (count) key: ' || element.key || ' question_id found: ' || question_id;
          IF num_slugs > 1 THEN
            SELECT INTO parent_question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1 offset 1) as slugs;
            -- get question id
            RAISE NOTICE 'parent_question_slug: %', parent_question_slug;
            SELECT INTO raw_group_id id FROM q_group where lower(name) = lower(parent_question_slug) and field_data_id = raw_field_data_id;

            RAISE NOTICE 'question_slug: %, field_data_id: %, raw_id: %, group_id: %', question_slug, raw_field_data_id, raw_field_data_id, raw_group_id;
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = raw_field_data_id AND group_id = (select id from q_group where lower(name) = lower(parent_question_slug) and field_data_id = raw_field_data_id);
          ELSE
            -- get question id
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = raw_field_data_id AND group_id IS NULL;
          END IF;
          RAISE NOTICE '---------> QUESTION ID UPDATED: %', question_id;
        END IF;

        CASE (element.key)
          -- get tenure type
          WHEN 'means_of_acquire' THEN
            data_means_aquired = element.value;
          WHEN 'date_land_possession' THEN
            data_date_land_possession = element.value;
          WHEN 'proprietorship' THEN
            CASE (element.value)
              WHEN 'allodial' THEN
                data_tenure_type = 'own';
              WHEN 'freehold' THEN
                data_tenure_type = 'own';
              WHEN 'lease' THEN
                data_tenure_type = 'lease';
              WHEN 'common_law_freehold' THEN
                data_tenure_type = 'own';
              WHEN 'occupy' THEN
                data_tenure_type = 'occupy';
              WHEN 'informal_occupy' THEN
                data_tenure_type = 'informal occupy';
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
                RAISE NOTICE 'Found question: %', question_id;

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

         RAISE NOTICE 'Cant find question: %', element.key;
          -- elements that have a key starting with an underscore, are not a survey question EXCEPT _geolocation
          IF left(element.key, 1) = '_' THEN
            CASE (lower(element.key))
              WHEN ('_id') THEN
                EXECUTE 'UPDATE respondent SET id_string = ' || quote_literal(element.value) || ' WHERE id = ' || data_respondent_id;
              WHEN ('_geolocation') THEN
                RAISE NOTICE 'Found geolocation:' ;
                  data_geojson = element.value::text;

                  RAISE NOTICE 'geojson: %', data_geojson;

                  SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

                  RAISE NOTICE 'GEOLOCATION VALUE %: ', data_geom;

                  -- Create new parcel

                  SELECT INTO data_parcel_id * FROM cd_create_parcel('survey_sketch','11',null,data_geom,null,null,'new description');

                  IF data_parcel_id IS NOT NULL THEN
                    RAISE NOTICE 'New parcel id: %', data_parcel_id;
                    UPDATE field_data SET parcel_id = data_parcel_id WHERE id = raw_field_data_id;
                  ELSE
                    RAISE NOTICE 'Cannot create parcel';
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
      IF raw_field_data_id IS NOT NULL THEN
        RAISE NOTICE 'Raw data is not null: %',raw_field_data_id ;
        EXECUTE 'UPDATE response SET field_data_id = ' || quote_literal(raw_field_data_id) || ' WHERE respondent_id = ' || data_respondent_id;
      END IF;
      IF data_parcel_id IS NOT NULL AND data_person_id IS NOT NULL THEN
        -- create relationship
        RAISE NOTICE 'Creating relationships tenure type: %', data_tenure_type ;
        SELECT INTO data_relationship_id * FROM cd_create_relationship
        (data_parcel_id,data_ckan_user_id,data_person_id,null,data_tenure_type,data_date_land_possession, data_means_aquired, null);

        IF data_relationship_id IS NOT NULL THEN
            RAISE NOTICE 'New relationship id: %', data_relationship_id;
        ELSE
            RAISE NOTICE 'No new relationship data_tenure_type: % data_parcel_id: % data_person_id: % data_ckan_user_id: %', data_tenure_type, data_parcel_id, data_person_id, data_ckan_user_id;
        END IF;
      END IF;
    END IF;
  ELSE
    RAISE NOTICE 'Cannot Find Survey';
    RETURN NEW;
  END IF;
  END LOOP;
  RETURN NEW;
END;
$cd_process_data$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS cd_process_data ON raw_data;
CREATE TRIGGER cd_process_data AFTER INSERT ON raw_data
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();

/******************************************************************

 TESTING cd_create_relationship_geometry

 SELECT * FROM cd_create_relationship_geometry(2,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 SELECT * FROM cd_create_relationship_geometry(4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 SELECT * FROM cd_create_relationship_geometry(24,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);


 select * from relationship_geometry
 select * from relationship
******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_relationship_geometry(relationship_id int, geojson text)
  RETURNS INTEGER AS $$
  DECLARE

  valid_id int;
  rg_id int; -- new relationship geometry id
  data_geojson character varying; -- geojson paramater
  data_geom geometry;

  BEGIN

    IF ($1 IS NOT NULL AND $2 IS NOT NULL) THEN

        -- validate relationshup id
        IF (cd_validate_relationship($1)) THEN

            data_geojson = geojson::text;

            -- get id from relationship table
            SELECT INTO valid_id id FROM relationship where id = $1;
            -- get geom form GEOJSON
            SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

            IF data_geom IS NOT NULL AND valid_id IS NOT NULL THEN

                -- add relationship geom column
                INSERT INTO relationship_geometry (geom) VALUES (data_geom) RETURNING id INTO rg_id;

                IF rg_id IS NOT NULL THEN
                    -- add relationship geom id in relationship table
                    UPDATE relationship SET geom_id = rg_id, time_updated = current_timestamp WHERE id = valid_id;
                    RETURN rg_id;
                END IF;

            ELSE
                RAISE NOTICE 'Invalid geometry: %', geom;
                RETURN NULL;
            END IF;

        ELSE
            RAISE NOTICE 'Invalid relationship id: %', relationship_id;
            RETURN NULL;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship id and Geometry required';
        RETURN NULL;
    END IF;

  END;

$$ LANGUAGE plpgsql VOLATILE;