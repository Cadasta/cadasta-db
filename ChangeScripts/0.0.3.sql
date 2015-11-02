/******************************************************************
Change Script 0.0.3
Date: 11/2/15

    1. Add project_id, area & length to relationship geometry table
    2. Update create relationship function to take geojson gemoetry object
    3. Update create relationship geometry function to take project_id & generate area and length
    4. Remove hard coded ckan user id from processdata ONA function trigger

******************************************************************/

ALTER TABLE relationship_geometry ADD COLUMN project_id integer not null references project(id);
ALTER TABLE relationship_geometry ADD COLUMN area numeric;
ALTER TABLE relationship_geometry ADD COLUMN length numeric;
ALTER TABLE relationship_history ADD COLUMN parcel_id int references parcel(id);
ALTER TABLE relationship_history ADD COLUMN party_id int references party(id);
ALTER TABLE relationship_history ADD COLUMN geom_id int references relationship_geometry (id);
ALTER TABLE relationship_history ADD COLUMN tenure_type int references tenure_type(id);
ALTER TABLE relationship_history ADD COLUMN acquired_date date;
ALTER TABLE relationship_history ADD COLUMN how_acquired character varying;

DROP FUNCTION cd_create_relationship_geometry(integer, text);
DROP FUNCTION cd_create_relationship(integer, integer, integer, integer, integer, character varying, date, character varying, character varying);

/******************************************************************

 cd_create_relationship

-- Create relationship with relationship geometry

SELECT * FROM cd_create_relationship(1,7,null,4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'lease',current_date,'stolen','family fortune');
SELECT * FROM cd_create_relationship(1,3,null,4,$anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'lease',current_date,null,null);

select * from relationship_geometry where id = 15
select * from relationship_history where relationship_id = 45
select * from relationship where id = 45

******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_relationship(
                                            p_id int,
                                            parcelId int,
                                            ckan_user_id int,
                                            partyId int,
                                            geojson character varying,
                                            tenureType character varying,
                                            acquiredDate date,
                                            howAcquired character varying,
                                            historyDescription character varying)
  RETURNS INTEGER AS $$
  DECLARE
  r_id integer;
  rh_id integer; -- relationship history id
  cd_parcel_id int;
  cd_ckan_user_id int;
  cd_party_id int;
  cd_geom_id int;
  cd_tenure_type_id int;
  cd_tenure_type character varying;
  cd_acquired_date date;
  cd_how_acquired character varying;
  cd_history_description character varying;
  cd_current_date date;
  cd_geojson character varying; -- geojson paramater



BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $4 IS NOT NULL AND $6 IS NOT NULL THEN

        IF(cd_validate_project(p_id)) THEN

        cd_history_description = historyDescription;
        cd_geojson = geojson::text;
        cd_acquired_date = acquiredDate;
        cd_how_acquired = howAcquired;

	    -- get parcel_id
        SELECT INTO cd_parcel_id id FROM parcel where id = $2 AND project_id = p_id;
        -- get party_id
        SELECT INTO cd_party_id id FROM party where id = $4 AND project_id = p_id;
        -- get tenure type id
        SELECT INTO cd_tenure_type_id id FROM tenure_type where type = $6;

        -- get ckan user id
        cd_ckan_user_id = ckan_user_id;

        SELECT INTO cd_current_date * FROM current_date;

        IF cd_tenure_type_id IS NULL THEN
            RAISE EXCEPTION 'Invalid Tenure Type';
        END IF;

        IF cd_party_id IS NULL THEN
            RAISE EXCEPTION 'Invalid party id';
        END IF;

        IF cd_parcel_id IS NOT NULL THEN

		        -- create relationship row
            INSERT INTO relationship (project_id,created_by,parcel_id,party_id,tenure_type,geom_id,acquired_date,how_acquired)
            VALUES (p_id,ckan_user_id,cd_parcel_id,cd_party_id, cd_tenure_type_id, cd_geom_id, cd_acquired_date,cd_how_acquired) RETURNING id INTO r_id;

            IF r_id IS NOT NULL THEN

                -- create relationship history
                INSERT INTO relationship_history (relationship_id,origin_id,active,description,date_modified, created_by, parcel_id, party_id, geom_id, tenure_type, acquired_date, how_acquired)
                VALUES (r_id,r_id,true,cd_history_description, cd_current_date, cd_ckan_user_id, (SELECT parcel_id FROM relationship where id = r_id), (SELECT party_id FROM relationship where id = r_id),
                (SELECT geom_id FROM relationship where id = r_id), (SELECT tenure_type FROM relationship where id = r_id), (SELECT acquired_date FROM relationship where id = r_id), (SELECT how_acquired FROM relationship where id = r_id)) RETURNING id INTO rh_id;

                IF geojson IS NOT NULL THEN
                    -- create relationship geometry
                    SELECT INTO cd_geom_id * FROM cd_create_relationship_geometry(p_id, r_id, cd_geojson);
                    IF cd_geom_id IS NOT NULL AND rh_id IS NOT NULL THEN
                        UPDATE relationship_history SET geom_id = cd_geom_id WHERE id = rh_id;
                        RETURN r_id;
                    ELSE
                        RAISE EXCEPTION 'Unable to create relationship geometry';
                    END IF;
                ELSE
                    RETURN r_id;
                END IF;

            ELSE
                RAISE EXCEPTION 'Unable to complete request';
            END IF;

        ELSE
            RAISE EXCEPTION 'Invalid parcel id';
            RETURN NULL;
        END IF;

	    ELSE
	        RAISE EXCEPTION 'Invalid project id';
	    END IF;

	ELSE
	    RAISE EXCEPTION 'The following parameters are required: cd_parcel_id, tenure_type, & party_id';
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


CREATE OR REPLACE FUNCTION cd_create_relationship_geometry(p_id int, relationship_id int, geojson text)
  RETURNS INTEGER AS $$
  DECLARE

  valid_relationship_id int;
  rg_id int; -- new relationship geometry id
  data_geojson character varying; -- geojson paramater
  data_geom geometry;
  cd_area numeric;
  cd_geom_type character varying;
  cd_length numeric;

  BEGIN

  IF cd_validate_project($1) THEN

    IF ($2 IS NOT NULL AND $3 IS NOT NULL) THEN

        -- validate relationshup id
        IF (cd_validate_relationship($1)) THEN

            data_geojson = geojson::text;

            -- get id from relationship table
            SELECT INTO valid_relationship_id id FROM relationship where id = $2 and project_id = p_id;
            -- get geom form GEOJSON
            SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

            IF data_geom IS NOT NULL AND valid_relationship_id IS NOT NULL THEN

            SELECT INTO cd_geom_type * FROM ST_GeometryType(data_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

             IF cd_geom_type iS NOT NULL THEN
                 CASE (cd_geom_type)
                    WHEN 'ST_Polygon' THEN
                        cd_area = ST_AREA(ST_TRANSFORM(data_geom,3857)); -- get area in meters
                    WHEN 'ST_LineString' THEN
                        cd_length = ST_LENGTH(ST_TRANSFORM(data_geom,3857)); -- get length in meters
                    ELSE
                        RAISE NOTICE 'Parcel is a point';
                 END CASE;
             END IF;

                -- add relationship geom column
                INSERT INTO relationship_geometry (project_id,geom, area, length) VALUES (p_id, data_geom, cd_area, cd_length) RETURNING id INTO rg_id;

                IF rg_id IS NOT NULL THEN
                    -- add relationship geom id in relationship table
                    UPDATE relationship SET geom_id = rg_id, time_updated = current_timestamp WHERE id = valid_relationship_id and project_id = p_id;

		    RAISE NOTICE 'rg_id IS NOT NULL %', rg_id;

                    RETURN rg_id;
                ELSE
			RAISE NOTICE 'rg_id IS NULL';
                END IF;

            ELSE
                RAISE EXCEPTION 'Invalid geometry';
            END IF;

        ELSE
            RAISE EXCEPTION 'Invalid relationship id';
        END IF;

    ELSE
        RAISE EXCEPTION 'Relationship id and Geometry required';
    END IF;

    ELSE
        RAISE EXCEPTION 'Invalid project';
    END IF;

  END;

$$ LANGUAGE plpgsql VOLATILE;


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

    -- get respondent first name
    SELECT INTO data_survey_first_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_first';
    -- get respondent last name
    SELECT INTO data_survey_last_name value::text FROM json_each_text(survey.value) WHERE key = 'applicant_name/applicant_name_last';
    -- get uuid of response
    SELECT INTO data_uuid value::text FROM json_each_text(survey.value) WHERE key = '_uuid';

    SELECT INTO data_submission_time value::text FROM json_each_text(survey.value) WHERE key = '_submission_time';
    SELECT INTO data_ona_data_id value::int FROM json_each_text(survey.value) WHERE key = '_id';

    -- process survey data only if there is a survey in the database that matches
    IF data_field_data_id IS NOT NULL THEN

        -- take the first name , last name fields out of the survey
        IF data_survey_first_name IS NOT NULL AND data_survey_last_name IS NOT NULL THEN
          SELECT INTO data_person_id * FROM cd_create_party (data_project_id, 'individual', data_survey_first_name,data_survey_last_name, null);
          RAISE NOTICE 'Created Person id: %', data_person_id;
        END IF;

      INSERT INTO respondent (field_data_id, uuid, submission_time, ona_data_id) VALUES (data_field_data_id,data_uuid,data_submission_time,data_ona_data_id) RETURNING id INTO data_respondent_id;

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
              WHEN 'contractual' THEN
                data_tenure_type = 'lease';
              ELSE
                RAISE NOTICE 'Improper Tenure Type';
            END CASE;
            RAISE NOTICE 'Found Loan';
          ELSE
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
                    UPDATE field_data SET parcel_id = data_parcel_id WHERE id = data_field_data_id;
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
            RAISE NOTICE 'New relationship id: %', data_relationship_id;
        ELSE
            RAISE NOTICE 'No new relationship data_tenure_type: % data_parcel_id: % data_person_id: % data_ckan_user_id: %', data_tenure_type, data_parcel_id, data_person_id, data_ckan_user_id;
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