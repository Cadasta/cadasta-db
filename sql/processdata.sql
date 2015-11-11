/******************************************************************

 Function: cd_process_data()

 Trigger to process FormHub data.json file after loading

******************************************************************/
--  Trigger to process FormHub data.json file after loading


CREATE OR REPLACE FUNCTION cd_process_data()
RETURNS TRIGGER AS $cd_process_data$
DECLARE
  raw_data_id integer; -- id of row in raw_data table
  raw_group_id integer;
  survey record;
  element record;
  options record;
  option record;
  data_uuid character varying;
  data_respondent_id integer;
  data_project_id integer;
  data_person_id int;
  data_ona_data_id integer;
  data_submission_time timestamp with time zone;
  data_geom_type character varying;
  data_geom geometry;
  data_area numeric;
  data_length numeric;
  question_id integer;
  question_id_l integer;
  data_relationship_id int;
  data_date_land_possession date;
  data_geojson character varying;
  data_means_aquired character varying;
  data_field_data_id integer; -- derived from submission _xform_id_string key and matched to id_string field in field_data table
  data_xform_id_string character varying; -- xform id string is used to find field data id
  data_tenure_type character varying;
  party_type party_type;
  tenure_type_id int;
  data_parcel_id int;
  data_survey_full_name character varying;
  data_survey_group_name character varying;
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

    -- get field data id
    SELECT INTO data_xform_id_string value::text FROM json_each_text(survey.value) WHERE key = '_xform_id_string';
    RAISE NOTICE 'id_string =: %', data_xform_id_string;

    -- get field_data_id by matching id_string with data's xform_id_string key
    SELECT INTO data_field_data_id id FROM field_data where id_string = data_xform_id_string;

    IF data_field_data_id IS NOT NULL THEN

    -- Get project id from field data table
    SELECT INTO data_project_id id FROM project where id = (SELECT project_id from field_data WHERE id_string = data_xform_id_string);

    RAISE NOTICE 'Project id: %', data_project_id;

    -- save field data id in raw_data table
    UPDATE raw_data SET field_data_id = data_field_data_id, project_id = data_project_id where id = raw_data_id;

    -- get respondent full name
    SELECT INTO data_survey_full_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name_full';
    -- get respondent group name
    SELECT INTO data_survey_group_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name_group';

    -- get respondent last name
    --SELECT INTO data_survey_last_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_last';
    -- get uuid of response
    SELECT INTO data_uuid value::text FROM json_each_text(survey.value) WHERE key = '_uuid';

    SELECT INTO data_submission_time value::text FROM json_each_text(survey.value) WHERE key = '_submission_time';
    SELECT INTO data_ona_data_id value::int FROM json_each_text(survey.value) WHERE key = '_id';

    SELECT INTO party_type value::party_type FROM json_each_text(survey.value) WHERE key = 'party_type';

    -- process survey data only if there is a survey in the database that matches
    IF data_field_data_id IS NOT NULL THEN

        -- Add respondent row and return id
        INSERT INTO respondent (field_data_id, uuid, submission_time, ona_data_id) VALUES (data_field_data_id,data_uuid,data_submission_time,data_ona_data_id) RETURNING id INTO data_respondent_id;

        -- take the first name , last name fields out of the survey
        IF party_type = 'individual' AND data_survey_full_name IS NOT NULL THEN
        raise notice 'party type: %  person name: %', party_type, data_survey_full_name;
          SELECT INTO data_person_id * FROM cd_create_party (data_project_id, party_type, data_survey_full_name, null, null, null, null, null);
        ELSIF party_type = 'group' AND data_survey_group_name IS NOT NULL THEN
        raise notice 'party type: %  group name: %', party_type, data_survey_group_name;
          SELECT INTO data_person_id * FROM cd_create_party (data_project_id, party_type, null, data_survey_group_name, null, null, null, null);
        END IF;

          IF data_person_id IS NOT NULL THEN
            UPDATE respondent SET party_id = data_person_id WHERE id = data_respondent_id;
          ELSE
            RAISE EXCEPTION 'Cannot create party %',party_type;
          END IF;

      count := count + 1;
      RAISE NOTICE 'Processing survey number % ...', count;
      FOR element IN (SELECT * FROM json_each_text(survey.value)) LOOP
      IF (element.key IS NOT NULL) THEN

        SELECT INTO question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1) as slugs;
        SELECT INTO num_slugs count(slugs) FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum) as slugs;
        SELECT INTO num_questions count(id) FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = data_field_data_id;
	-- get question id
        SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = data_field_data_id;

        IF num_questions > 1 THEN
          RAISE NOTICE '---------> MULTIPLE QUESTIONS FOUND!!!: %', num_questions || ' (count) key: ' || element.key || ' question_id found: ' || question_id;
          IF num_slugs > 1 THEN
            SELECT INTO parent_question_slug slugs FROM (SELECT slugs.*, row_number() OVER () as rownum from regexp_split_to_table(element.key, '/') as slugs order by rownum desc limit 1 offset 1) as slugs;
            -- get question id
            RAISE NOTICE 'parent_question_slug: %', parent_question_slug;
            SELECT INTO raw_group_id id FROM q_group where lower(name) = lower(parent_question_slug) and field_data_id = data_field_data_id;

            RAISE NOTICE 'question_slug: %, field_data_id: %, raw_id: %, group_id: %', question_slug, data_field_data_id, data_field_data_id, raw_group_id;
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = data_field_data_id AND group_id = (select id from q_group where lower(name) = lower(parent_question_slug) and field_data_id = data_field_data_id);
          ELSE
            -- get question id
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = data_field_data_id AND group_id IS NULL;
          END IF;
          RAISE NOTICE '---------> QUESTION ID UPDATED: %', question_id;
        END IF;

        CASE (element.key)
          -- get tenure type
          WHEN 'means_of_acquire' THEN
            data_means_aquired = element.value;
          WHEN 'date_land_possession' THEN
            data_date_land_possession = element.value;
          WHEN 'tenure_type' THEN
          RAISE NOTICE 'made it to tenure type %', element.value;
            CASE (element.value)
              WHEN 'indigenous_land_rights' THEN
                data_tenure_type = 'indigenous land rights';
              WHEN 'joint_tenancy' THEN
                data_tenure_type = 'joint tenancy';
              WHEN 'tenancy_in_common' THEN
                data_tenure_type = 'tenancy in common';
              WHEN 'undivided_co_ownership' THEN
                data_tenure_type = 'undivided co-ownership';
              WHEN 'easment' THEN
                data_tenure_type = 'easement';
              WHEN 'equitable_servitude' THEN
                data_tenure_type = 'equitable servitude';
              WHEN 'mineral_rights' THEN
                data_tenure_type = 'mineral rights';
              WHEN 'water_rights' THEN
                data_tenure_type = 'water rights';
               WHEN 'concessionary_rights' THEN
                data_tenure_type = 'concessionary rights';
               WHEN 'carbon_rights' THEN
                data_tenure_type = 'carbon rights';
              ELSE
                RAISE EXCEPTION 'Invalid tenure type CASE %', data_tenure_type;
            END CASE;
          ELSE
        END CASE;

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
                  EXECUTE 'INSERT INTO response (respondent_id, question_id, numeric) VALUES (' || data_respondent_id || ','|| question_id || ',' ||  element.value || ');';
                ELSE
                  EXECUTE 'INSERT INTO response (respondent_id, question_id, numeric) VALUES (' || data_respondent_id || ','|| question_id || ', NULL);';
                END IF;
              ELSE
	          END IF;
            ELSE
              EXECUTE 'INSERT INTO response (respondent_id, question_id, text) VALUES (' || data_respondent_id || ','|| question_id || ',' || quote_literal(element.value) ||');';
          END CASE;
        -- question is not found in the database
        ELSE

         RAISE NOTICE 'Cant find question: %', element.key;
          -- elements that have a key starting with an underscore, are not a survey question EXCEPT _geolocation
          IF left(element.key, 1) = '_' THEN
            CASE (lower(element.key))
              WHEN ('_geolocation') THEN
                RAISE NOTICE 'Found geolocation:' ;
                  data_geojson = element.value::text;

                  RAISE NOTICE 'geojson: %', data_geojson;

                  SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326); -- convert to LAT LNG GEOM

                  SELECT INTO data_geojson * FROM ST_AsGeoJSON(data_geom);

                  RAISE NOTICE 'GEOLOCATION VALUE %: ', data_geom;

		          -- Create new parce
                  SELECT INTO data_parcel_id * FROM cd_create_parcel(data_project_id,'survey_sketch',data_geojson,null,null,'new description');

                  IF data_parcel_id IS NOT NULL THEN
                    RAISE NOTICE 'New parcel id: %', data_parcel_id;
                    UPDATE respondent SET parcel_id = data_parcel_id WHERE id = data_respondent_id;
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
      IF data_field_data_id IS NOT NULL THEN
        RAISE NOTICE 'Raw data is not null: %',data_field_data_id ;
        EXECUTE 'UPDATE response SET field_data_id = ' || quote_literal(data_field_data_id) || ' WHERE respondent_id = ' || data_respondent_id;
      END IF;
      IF data_parcel_id IS NOT NULL AND data_person_id IS NOT NULL THEN
        -- create relationship
        RAISE NOTICE 'Creating relationships tenure type: % project_id %', data_tenure_type, data_project_id;
        SELECT INTO data_relationship_id * FROM cd_create_relationship
        (data_project_id,data_parcel_id,data_ckan_user_id,data_person_id,null,data_tenure_type,data_date_land_possession, data_means_aquired, null);

        IF data_relationship_id IS NOT NULL THEN
	    UPDATE respondent SET relationship_id = data_relationship_id WHERE id = data_respondent_id;
        ELSE
	    RAISE EXCEPTION 'Cannot create relationship';
        END IF;
      END IF;
    END IF;
  ELSE
    RAISE NOTICE 'Cannot find field data form';
    RETURN NEW;
  END IF;
  END LOOP;
  RETURN NEW;
END;
$cd_process_data$ LANGUAGE plpgsql;

/**
CREATE TRIGGER cd_process_data AFTER INSERT ON raw_data
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();

    **/
