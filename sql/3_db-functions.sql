/******************************************************************
    Create New field data form

    cd_create_field_data

******************************************************************/

-- Create new Field Data

CREATE OR REPLACE FUNCTION cd_create_field_data(project_id integer, id_string character varying, form_id bigint)
  RETURNS INTEGER AS $$
  DECLARE
  f_id integer;
  field_data_id_string character varying;
  p_id integer;
BEGIN

    field_data_id_string = id_string;

    SELECT INTO p_id id FROM project WHERE id = project_id;

    IF field_data_id_string IS NOT NULL AND p_id IS NOT NULL AND form_id IS NOT NULL THEN

	-- Create survey and return survey id
    INSERT INTO field_data (project_id, id_string, form_id) VALUES (project_id, field_data_id_string, form_id) RETURNING id INTO f_id;
	    RETURN f_id; -- field data id
    ELSE
        RETURN f_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


/******************************************************************
    import_form_json

    Import raw JSON form string

******************************************************************/
CREATE OR REPLACE FUNCTION cd_import_form_json(json_string character varying)
RETURNS boolean AS $$
DECLARE
  raw_form_id int;
  rec record;
BEGIN

  IF $1 IS NOT NULL THEN

    INSERT INTO raw_form (json) VALUES (json_string::json) RETURNING id INTO raw_form_id;

    IF raw_form_id IS NOT NULL THEN
        RAISE NOTICE 'Succesfully inserted raw json form, id: %', raw_form_id;
        RETURN TRUE;
     END IF;
  ELSE
        RETURN FALSE;
  END IF;

END;$$ language plpgsql;

/******************************************************************
    import_data_json

    Import raw JSON data string

******************************************************************/
CREATE OR REPLACE FUNCTION cd_import_data_json(json_string character varying)
RETURNS BOOLEAN AS $$
DECLARE
  raw_data_id int;
  raw_field_data_id int;
  rec record;
BEGIN

  IF $1 IS NOT NULL THEN

    INSERT INTO raw_data (json) VALUES (json_string::json) RETURNING id INTO raw_data_id;

    SELECT INTO raw_field_data_id field_data_id from raw_data where id = raw_data_id;

    IF raw_data_id IS NOT NULL AND raw_field_data_id IS NOT NULL THEN
        RAISE NOTICE 'Succesfully inserted raw json data, id: %', raw_data_id;
        RETURN TRUE;
    ELSE
        -- Remove raw data row
        DELETE FROM raw_data where id = raw_data_id;
	    RETURN FALSE;
    END IF;
  ELSE
    RETURN FALSE;
  END IF;

END;$$ language plpgsql;


/******************************************************************
    is_numeric

    Function to determine if value is numeric

******************************************************************/
CREATE OR REPLACE FUNCTION is_numeric(text) RETURNS BOOLEAN AS $$
DECLARE x NUMERIC;
BEGIN
    x = $1::NUMERIC;
    RETURN TRUE;
EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

/******************************************************************
    cd_create_party

    Create new party

    -- Create new party Ian O'Guin for project 1
    SELECT * FROM cd_create_party(1, 'individual', 'Ian', 'O''Guin', null);
    -- Create new party group Wal Mart for project 1
    SELECT * FROM cd_create_party(1, 'group', null, null, 'Wal-Mart');

******************************************************************/


CREATE OR REPLACE FUNCTION cd_create_party(project_id int, cd_party_type party_type, first_name character varying, last_name character varying, cd_group_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
  cd_party_type_lower character varying;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND (($3 IS NOT NULL) OR ($5 IS NOT NULL)) THEN

        IF ($3 IS NOT NULL AND $5 IS NOT NULL) THEN
            RAISE EXCEPTION 'Cannot have an individual and group name';
        END IF;

        IF ($4 IS NOT NULL AND $3 IS NULL) THEN
            RAISE EXCEPTION 'Cannot have an last name without first name';
        END IF;

        IF ($3 IS NOT NULL AND $2 = 'group') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;

        IF ($5 IS NOT NULL AND $2 = 'individual') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;

        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, type, first_name, last_name, group_name) VALUES (cd_project_id, cd_party_type, first_name,last_name, cd_group_name) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RAISE EXCEPTION 'project_id, party_type , first_name OR group_name required';
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;



/********************************************************

    cd_create_parcel

    select * from parcel

    SELECT * FROM cd_create_parcel(1, 'digitized', null, 'Commercial', null, 'insert description here');

    SELECT * FROM cd_create_parcel(3, 'survey_sketch', $anystr${
        "type": "Polygon",
        "coordinates": [
          [
            [
              -121.73335433006287,
              44.571446955240106
            ],
            [
              -121.73388004302979,
              44.57033871490996
            ],
            [
              -121.7328178882599,
              44.56994127185396
            ],
            [
              -121.73189520835876,
              44.570804942725566
            ],
            [
              -121.73335433006287,
              44.571446955240106
            ]
          ]
        ]
      }$anystr$, 'Residential', null, 'insert description here');


      SELECT * FROM cd_create_parcel(1, 'digitized', 	$anystr${
        "type": "LineString",
        "coordinates": [
          [
            -121.73326581716537,
            44.5723908536272
          ],
          [
            -121.7331075668335,
            44.57247110339075
          ]
        ]
      }$anystr$, 'Commercial', null, 'insert description here');


-- select * from parcel
-- select * from parcel_history

*********************************************************/

-- Function: cd_create_parcel(integer, character varying, geometry, land_use, character varying, character varying)

-- DROP FUNCTION cd_create_parcel(integer, character varying, characer varying, land_use, character varying, character varying);

CREATE OR REPLACE FUNCTION cd_create_parcel(project_id integer,
                                            spatial_source character varying,
                                            geojson character varying,
                                            land_use land_use,
                                            gov_pin character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  ph_id integer;
  cd_project_id integer;
  cd_geometry geometry;
  cd_geom_type character varying;
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_geojson character varying;
  cd_gov_pin character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- spatial source and project id required
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

        SELECT INTO cd_project_id id FROM project where id = $1;

        IF cd_project_id IS NOT NULL THEN
            SELECT INTO cd_current_date * FROM current_date;

            cd_gov_pin := gov_pin;
            cd_land_use := land_use;
            cd_spatial_source = spatial_source;
            cd_history_description = history_description;
            cd_geojson = geojson;

            SELECT INTO cd_geometry * FROM ST_SetSRID(ST_GeomFromGeoJSON(cd_geojson),4326); -- convert to LAT LNG GEOM

            SELECT INTO cd_spatial_source_id id FROM spatial_source WHERE type = cd_spatial_source;

            SELECT INTO cd_geom_type * FROM ST_GeometryType(cd_geometry); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

             IF cd_geom_type iS NOT NULL THEN
                  RAISE NOTICE 'cd_geom_type: %', cd_geom_type;
                 CASE (cd_geom_type)
                    WHEN 'ST_Polygon' THEN
                        cd_area = ST_AREA(ST_TRANSFORM(cd_geometry,3857)); -- get area in meters
                    WHEN 'ST_LineString' THEN
                        cd_length = ST_LENGTH(ST_TRANSFORM(cd_geometry,3857)); -- get length in meters
                        RAISE NOTICE 'length: %', cd_length;
                    ELSE
                        RAISE NOTICE 'Parcel is a point';
                 END CASE;
             END IF;

	        IF cd_spatial_source_id IS NOT NULL THEN
	                -- Create parcel record
				    INSERT INTO parcel (spatial_source,project_id,geom,area,length,land_use,gov_pin) VALUES
				    (cd_spatial_source_id,cd_project_id,cd_geometry,cd_area,cd_length,cd_land_use,cd_gov_pin) RETURNING id INTO p_id;
				    RAISE NOTICE 'Successfully created parcel, id: %', p_id;

                    -- Create parcel history record
				    INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified, spatial_source, area, length, geom, land_use, gov_pin)
				    VALUES (p_id,p_id,cd_history_description,cd_current_date, cd_spatial_source_id, cd_area, cd_length, cd_geometry, cd_land_use, cd_gov_pin)
				    RETURNING id INTO ph_id;

				    RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;
		    ELSE
		        RAISE EXCEPTION 'Invalid spatial source';
		    END IF;

	        IF p_id IS NOT NULL THEN
		        RETURN p_id;
	        ELSE
		        RAISE EXCEPTION 'Unable to create Parcel';
	        END IF;
	    ELSE
	        RAISE EXCEPTION 'Invalid project id';
	    END IF;

	ELSE
	    RAISE EXCEPTION 'The following parameters are required: spatial_source, project_id';
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


/******************************************************************

 cd_create_relationship

-- Create relationship with relationship geometry

SELECT * FROM cd_create_relationship(1,7,null,4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'lease',current_date,'stolen','family fortune');
SELECT * FROM cd_create_relationship(1,3,null,4,$anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'lease',current_date,null,null);


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
  data_geom geometry;
  cd_geom_type character varying;
  cd_party_id int;
  cd_tenure_type_id int;
  cd_area numeric;
  cd_length numeric;
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
        cd_acquired_date = acquiredDate;
        cd_how_acquired = howAcquired;

	    -- get parcel_id
        SELECT INTO cd_parcel_id id FROM parcel where id = $2 AND project_id = p_id;
        -- get party_id
        SELECT INTO cd_party_id id FROM party where id = $4 AND project_id = p_id;
        -- get tenure type id
        SELECT INTO cd_tenure_type_id id FROM tenure_type where type = $6;

        -- create relationship geometry
        SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(geojson),4326);

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
            INSERT INTO relationship (geom, length, area, project_id,created_by,parcel_id,party_id,tenure_type,acquired_date,how_acquired)
            VALUES (data_geom, cd_length, cd_area, p_id,ckan_user_id,cd_parcel_id,cd_party_id, cd_tenure_type_id, cd_acquired_date,cd_how_acquired) RETURNING id INTO r_id;

            IF r_id IS NOT NULL THEN

                -- create relationship history
                INSERT INTO relationship_history (area, length, relationship_id,origin_id,active,description,date_modified, created_by, parcel_id, party_id, geom, tenure_type, acquired_date, how_acquired)

                VALUES ((SELECT area FROM relationship where id = r_id), (SELECT length FROM relationship where id = r_id), r_id,r_id,true,cd_history_description, cd_current_date, cd_ckan_user_id, (SELECT parcel_id FROM relationship where id = r_id), (SELECT party_id FROM relationship where id = r_id),
                (SELECT geom FROM relationship where id = r_id), (SELECT tenure_type FROM relationship where id = r_id), (SELECT acquired_date FROM relationship where id = r_id), (SELECT how_acquired FROM relationship where id = r_id))
                RETURNING id INTO rh_id;

                RETURN r_id;

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

CREATE TRIGGER cd_process_data AFTER INSERT ON raw_data
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();


/******************************************************************
 TESTING cd_create_project_extents

 SELECT * FROM cd_create_project_extents(2,$anystr${"type": "Polygon",
    "coordinates": [
        [
            [
                -122.32929289340971,
                47.674757902221806
            ],
            [
                -122.32930362224579,
                47.67455201393344
            ],
            [
                -122.32899785041809,
                47.67455923809767
            ],
            [
                -122.32889592647551,
                47.67462064345317
            ],
            [
                -122.32885301113127,
                47.6747253935987
            ],
            [
                -122.32929289340971,
                47.674757902221806
            ]
        ]
    ]
}$anystr$);

 SELECT * FROM cd_create_project_extents(1,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 select * from project_extents;
 select * from relationship_geometry
 select * from relationship
******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_project_extents(project_id int, geojson text)
  RETURNS INTEGER AS $$
  DECLARE

  p_id int;
  pe_id int; -- new project extents id
  data_geojson character varying; -- geojson paramater
  data_geom geometry;
  cd_geom_type character varying;

  BEGIN

    IF ($1 IS NOT NULL AND $2 IS NOT NULL) THEN

        data_geojson = geojson::text;

        SELECT INTO p_id id FROM project WHERE id = $1;

        IF (cd_validate_project(p_id)) THEN

            -- get geom form GEOJSON
            SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

            SELECT INTO cd_geom_type * FROM ST_GeometryType(data_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

            IF data_geom IS NOT NULL AND cd_geom_type = 'ST_Polygon' THEN
                INSERT INTO project_extents (project_id,geom) VALUES (p_id, data_geom) RETURNING id INTO pe_id;
                RETURN pe_id;
            ELSE
                RAISE NOTICE 'Invalid GeoJSON';
                RETURN pe_id;
            END IF;

        ELSE
            RAISE NOTICE 'Invalid Project id';
            RETURN pe_id;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship id and Geometry required';
        RETURN pe_id;
    END IF;

  END;

$$ LANGUAGE plpgsql VOLATILE;

  /********************************************************

    cd_create_organization

    select * from organization;

    SELECT * FROM cd_create_organization('grow','123fadsaa', 'GROW Project', 'Created in response to GROW');`

*********************************************************/

CREATE OR REPLACE FUNCTION cd_create_organization(ckan_name character varying, ckan_org_id character varying , title character varying, description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer;
  cd_ckan_org_name character varying;
  cd_description character varying;
  cd_title character varying;
  cd_ckan_id character varying;
BEGIN

    cd_ckan_org_name = $1;
    cd_ckan_id = $2;
    cd_title = $3;
    cd_description = $4;

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

	    -- Save the original organization ID variable
        INSERT INTO organization (title, description, ckan_name, ckan_id) VALUES (cd_title,cd_description,cd_ckan_org_name,cd_ckan_id) RETURNING id INTO o_id;

	    RETURN o_id;
    ELSE
        RAISE EXCEPTION 'Missing ckan_name or ckan_org_id';
        RETURN o_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


   /********************************************************

    cd_create_project

    select * from project;
    select * from organization;

    SELECT * FROM cd_create_project(1,'meddyypilot', 'Meddy', 'Medeyy Pilor', 'descripton', '1qewdasaseq1eqeweqasda11ewq');

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_project(org_id integer, ckan_project_id character varying, ckan_name character varying, title character varying, description character varying, api_key character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  o_id integer;
  cd_ckan_name character varying;
  cd_ckan_project_id character varying;
  cd_title character varying;
  cd_description character varying;
  cd_api_key character varying;
BEGIN

    cd_ckan_project_id = regexp_replace($2, U&'\2028', '', 'g');
    cd_ckan_name = $3;
    cd_title = $4;
    cd_description = $5;
    cd_api_key = $6;

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        -- Grab org id from org table
        SELECT INTO o_id id FROM organization WHERE id = $1;

        -- Validate organization id
        IF o_id IS NOT NULL AND cd_validate_organization($1) THEN

	        -- Create project and store project id
            INSERT INTO project (organization_id, ckan_name, ckan_id, title, description, ona_api_key) VALUES (o_id, cd_ckan_name, cd_ckan_project_id,cd_title, cd_description, cd_api_key) RETURNING id INTO p_id;

            RETURN p_id;
        ELSE
            RAISE EXCEPTION 'Invalid organization';
            RETURN p_id;
        END IF;

    ELSE
        RAISE EXCEPTION 'Parameters org_id, ckan_project_id, and ckan_name required';
        RETURN p_id;
    END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

-- Create new resource
/********************************************************

    cd_create_resource

    -- Create resource for parcel 20 in project 1
    SELECT * FROM cd_create_resource(1,'parcel',20,'http://www.cadasta.org/20/parcel','Description', 'filename');

    -- Create resource for project 3
    SELECT * FROM cd_create_resource(3,'project',3,'http://www.cadasta.org/3/project','Description', 'daniel-home');

    -- Create resource for relationship 30 in project 3
    SELECT * FROM cd_create_resource(3,'relationship',30,'http://www.cadasta.org/30/relationship','Description', 'filename');

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_resource(projectId int, resource_type character varying, resource_type_id integer, url character varying, description character varying, filename character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer; -- organization id
  p_id integer; -- project id
  r_id integer; -- resource id
  type_id integer; -- type of resource id (parcel, party, or relationship id)
  cd_description character varying;
  cd_url character varying;
  cd_file_name character varying;
BEGIN

    cd_description = description;
    cd_url = url;
    cd_file_name = filename;

    -- project id, resource type, and url are required
    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL AND $4 IS NOT NULL AND $6 IS NOT NULL THEN

        -- validate project id
        SELECT INTO p_id id FROM project WHERE id = $1;

        IF cd_validate_project(p_id) THEN

                CASE lower(resource_type)
                    -- ensure resource type is supported
                    WHEN 'parcel' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM parcel WHERE id = resource_type_id AND project_id = p_id;

                        -- validate parcel id
                        IF cd_validate_parcel(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url, file_name) VALUES (p_id, cd_description, cd_url, cd_file_name) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_parcel(parcel_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE EXCEPTION 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE EXCEPTION 'Invalid parcel id';
                            RETURN r_id;
                        END IF;
                    WHEN 'party' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM party WHERE id = resource_type_id AND project_id = p_id;

                        -- validate parcel id
                        IF cd_validate_party(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url,file_name) VALUES (p_id, cd_description, cd_url,cd_file_name) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_party(party_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE EXCEPTION 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE EXCEPTION 'Invalid party id';
                            RETURN r_id;
                        END IF;
                    WHEN 'relationship' THEN
                        -- get resource type id from relationship table
                        SELECT INTO type_id id FROM relationship WHERE id = resource_type_id AND project_id = p_id;

                        -- validate parcel id
                        IF cd_validate_relationship(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url,file_name) VALUES (p_id, cd_description, cd_url,cd_file_name) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_relationship(relationship_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE EXCEPTION 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE EXCEPTION 'Invalid relationship id';
                            RETURN r_id;
                        END IF;
                    WHEN 'project' THEN

                        -- get resource type id from project table
                        SELECT INTO type_id id FROM project WHERE id = resource_type_id;

                        -- validate project id
                        IF cd_validate_project(type_id) AND type_id = p_id THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url,file_name) VALUES (p_id, cd_description, cd_url,cd_file_name) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_project(project_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE EXCEPTION 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE EXCEPTION 'Invalid project id';
                            RETURN r_id;
                        END IF;

                ELSE
                    RAISE EXCEPTION 'Invalid resource type';
                    RETURN r_id;
                END CASE;

        ELSE
            RAISE EXCEPTION 'Invalid project id';
            RETURN r_id;
        END IF;
    ELSE
        RAISE EXCEPTION 'project_id, resource_type, and url are required';
        RETURN r_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;



/********************************************************

    cd_update_parcel

    select * from parcel_history where parcel_id = 3

    SELECT NOT(ST_Equals((SELECT geom FROM parcel_history where id = 14), (select geom from parcel_history where id = 15)))

    -- Update parcel geom, spatial_source, land_use, gov_pin and description
    SELECT * FROM cd_update_parcel (1, 3, $anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'digitized',
    'Commercial' , '331321sad', 'we have a new description');

    -- Update parcel geometry
    SELECT * FROM cd_update_parcel (1, 3, $anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$, null, null , null, null);

    -- Should return an exception: 'All values are null'
    SELECT * FROM cd_update_parcel (1, 3, null, null, null , null, null);

    -- Should return exception: 'Invalid spatial_source'
    SELECT * FROM cd_update_parcel (1, 3, null, 'survey_sketchh', null , null, null);

    -- Should return exception: 'Project and Parcel id required'
    SELECT * FROM cd_update_parcel (1, null, null, 'survey_sketch', null , null, null);

*********************************************************/

CREATE OR REPLACE FUNCTION cd_update_parcel(	     cd_project_id integer,
                                                     cd_parcel_id integer,
                                                     cd_geojson character varying,
                                                     cd_spatial_source character varying,
                                                     cd_land_use land_use,
                                                     cd_gov_pin character varying,
                                                     cd_description character varying
                                                     )
  RETURNS INTEGER AS $$
  DECLARE
  pro_id integer;   -- project id
  p_id integer;     -- parcel id
  ph_id integer;
  cd_geom geometry;
  cd_new_version integer;
  cd_current_date date;
  cd_geom_type character varying;
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source_id integer;

  BEGIN
    -- 1. update parcel record
    -- 2. create parcel hisotry record

    IF $1 IS NULL OR $2 IS NULL THEN
        RAISE EXCEPTION 'Project and Parcel id required';
    END IF;

    SELECT INTO pro_id id FROM project WHERE id = $1;

    IF NOT(SELECT * FROM cd_validate_project(pro_id)) THEN
        RAISE EXCEPTION 'Invalid project id';
    END IF;

    SELECT INTO p_id id FROM parcel WHERE id = $2 and project_id = $1;

    IF cd_validate_parcel(p_id) THEN

        SELECT INTO cd_spatial_source_id id FROM spatial_source where type = cd_spatial_source;

        IF cd_spatial_source_id IS NULL AND cd_spatial_source IS NOT NULL THEN
	    RAISE EXCEPTION 'Invalid spatial source.';
        END IF;

        SELECT INTO cd_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(cd_geojson),4326); -- convert to LAT LNG GEOM

        -- Ensure at least one is not null
        IF cd_geojson IS NOT NULL OR cd_spatial_source IS NOT NULL OR cd_land_use IS NOT NULL or cd_gov_pin IS NOT NULL OR cd_description IS NOT NULL THEN
           SELECT INTO cd_geom_type * FROM ST_GeometryType(cd_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

             -- need geometry type for area, length calculation
             IF cd_geom_type iS NOT NULL THEN
                  RAISE NOTICE 'cd_geom_type: %', cd_geom_type;
                 CASE (cd_geom_type)
                    WHEN 'ST_Polygon' THEN
                        cd_area = ST_AREA(ST_TRANSFORM(cd_geom,3857)); -- get area in meters
                        UPDATE parcel SET area = cd_area, length = cd_length WHERE id = p_id;
                    WHEN 'ST_LineString' THEN
                        cd_length = ST_LENGTH(ST_TRANSFORM(cd_geom,3857)); -- get length in meters
                        UPDATE parcel SET length = cd_length, area = cd_area WHERE id = p_id;
                    ELSE
                        RAISE NOTICE 'Parcel is a point';
                 END CASE;
             END IF;

            -- increment version for parcel_history record
            SELECT INTO cd_new_version SUM(version + 1) FROM parcel_history where parcel_id = p_id GROUP BY VERSION ORDER BY VERSION DESC LIMIT 1;
            SELECT INTO cd_current_date * FROM current_date;

            -- update parcel record
            UPDATE parcel
            SET
            geom = COALESCE(cd_geom, geom),
            spatial_source = COALESCE(cd_spatial_source_id, spatial_source),
            land_use = COALESCE (cd_land_use, land_use),
            gov_pin  = COALESCE (cd_gov_pin, gov_pin)
            WHERE id = p_id;

            IF cd_new_version IS NOT NULL THEN
                -- add parcel history record
                INSERT INTO parcel_history(
                parcel_id, origin_id, version, description, date_modified,
                spatial_source, user_id, area, length, geom, land_use, gov_pin)
	            VALUES (p_id, p_id, cd_new_version, COALESCE(cd_description,(SELECT description FROM parcel_history where parcel_id = p_id GROUP BY description, version ORDER BY version DESC LIMIT 1)), cd_current_date,
                (SELECT spatial_source FROM parcel WHERE id = p_id), (SELECT user_id FROM parcel WHERE id = p_id), (SELECT area FROM parcel WHERE id = p_id), (SELECT length FROM parcel where id = p_id), (SELECT geom FROM parcel where id = p_id),
                (SELECT land_use FROM parcel WHERE id = p_id), (SELECT gov_pin FROM parcel WHERE id = p_id)) RETURNING id INTO ph_id;

                -- Deactivate all versions lower than new version
                UPDATE parcel_history SET active = false WHERE parcel_id = p_id AND version < cd_new_version;
            ELSE
	            RAISE EXCEPTION 'Cannot increment version';
            END IF;

            IF ph_id IS NOT NULL THEN
		        RETURN ph_id;
		    END IF;

        ELSE
            RAISE EXCEPTION 'All values are null';
        END IF;

    ELSE
        RAISE EXCEPTION 'Invalid Parcel id';
    END IF;

END;
$$ LANGUAGE plpgsql VOLATILE;


/********************************************************

    cd_update_relationship

    SELECT * FROM cd_create_relationship(1,7,null,4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'lease',current_date,'stolen','family fortune');

    -- Update relationship 1's tenure type, how acqured, and history description
    SELECT * FROM cd_update_relationship(1,1,null,null,null,'occupy',null, 'taken over by government', 'informed in the mail');

    -- Update relationship 1's geometry
    SELECT * FROM cd_update_relationship(1,1,null,null,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,null,null,null,null);

    -- Update relationship with wrong project id:
    SELECT * FROM cd_update_relationship(3,1,null,null,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,null,null,null,null);

    -- Update no values on relationship 1
    SELECT * FROM cd_update_relationship(1,1,null,null,null,null,null,null,null);

*********************************************************/

CREATE OR REPLACE FUNCTION cd_update_relationship(	cd_project_id integer,
							cd_relationship_id integer,
							cd_party_id int,
							cd_parcel_id int,
							geojson character varying,
							cd_tenure_type character varying,
							cd_acquired_date date,
							cd_how_acquired character varying,
							cd_history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  r_id integer;   -- relationship id
  p_id integer;     -- project id
  rh_id int;
  valid_party_id int;
  valid_relationship_id int;
  valid_parcel_id int;
  cd_geom geometry;
  cd_area numeric;
  cd_length numeric;
  cd_geom_type character varying;
  cd_tenure_type_id int;
  cd_new_version int;
  cd_current_date date;
  cd_parent_id date;

  BEGIN
    -- 1. update relationship record
    -- 2. create parcel history record

    SELECT INTO valid_relationship_id id FROM relationship where id = $2 and project_id = $1;
    SELECT INTO valid_party_id id FROM party where id = $3 and project_id = $1;
    SELECT INTO valid_parcel_id id FROM parcel where id = $4 and project_id = $1;
    SELECT INTO cd_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(geojson),4326); -- convert to LAT LNG GEOM
    SELECT INTO cd_geom_type * FROM ST_GeometryType(cd_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)
    SELECT INTO cd_tenure_type_id id FROM tenure_type where type = cd_tenure_type;

    IF NOT(SELECT * FROM cd_validate_project($1)) THEN
        RAISE EXCEPTION 'Invalid project';
    END IF;

    IF NOT(SELECT * FROM cd_validate_relationship(valid_relationship_id)) THEN
        RAISE EXCEPTION 'Invalid relationship';
    END IF;

    IF $6 IS NOT NULL AND cd_tenure_type_id IS NULL THEN
	RAISE EXCEPTION 'Invalid tenure type';
    END IF;

    IF $3 IS NOT NULL AND NOT(SELECT * FROM cd_validate_party(valid_party_id)) THEN
        RAISE EXCEPTION 'Invalid party';
    END IF;

    IF $4 IS NOT NULL AND NOT(SELECT * FROM cd_validate_parcel(valid_parcel_id)) THEN
        RAISE EXCEPTION 'Invalid parcel';
    END IF;

    IF $3 IS NULL AND $4 IS NULL AND $5 IS NULL AND $6 IS NULL AND $7 IS NULL AND $8 IS NULL THEN
	RAISE EXCEPTION 'All updatable values are null';
    END IF;

    IF cd_geom_type iS NOT NULL THEN
        CASE (cd_geom_type)
        WHEN 'ST_Polygon' THEN
            cd_area = ST_AREA(ST_TRANSFORM(cd_geom,3857)); -- get area in meters
            UPDATE relationship SET area = cd_area, length = cd_length WHERE id = valid_relationship_id;
        WHEN 'ST_LineString' THEN
            cd_length = ST_LENGTH(ST_TRANSFORM(cd_geom,3857)); -- get length in meters
            UPDATE relationship SET area = cd_area, length = cd_length WHERE id = valid_relationship_id;
        ELSE
            RAISE NOTICE 'geom is a point';
        END CASE;
    END IF;

    -- increment version for parcel_history record
    SELECT INTO cd_new_version SUM(version + 1) FROM relationship_history where relationship_id = valid_relationship_id GROUP BY VERSION ORDER BY VERSION DESC LIMIT 1;
    SELECT INTO cd_current_date * FROM current_date;

    -- update parcel record
    UPDATE relationship
    SET
    geom = COALESCE(cd_geom, geom),
    party_id = COALESCE(valid_party_id, party_id),
    parcel_id = COALESCE (valid_parcel_id, parcel_id),
    tenure_type  = COALESCE (cd_tenure_type_id, tenure_type),
    acquired_date = COALESCE (cd_acquired_date, acquired_date),
    how_acquired = COALESCE (cd_how_acquired, how_acquired)
    WHERE id = $2;

    IF cd_new_version IS NOT NULL THEN

        -- create relationship history
        INSERT INTO relationship_history (version, area, length, relationship_id, origin_id,description,date_modified, parcel_id, party_id, geom, tenure_type, acquired_date, how_acquired)

        VALUES (cd_new_version,
        (SELECT area FROM relationship where id = valid_relationship_id),
        (SELECT length FROM relationship where id = valid_relationship_id),
        valid_relationship_id,
        valid_relationship_id,
        COALESCE(cd_history_description,(SELECT description FROM relationship_history where relationship_id = valid_relationship_id GROUP BY description, version ORDER BY version DESC LIMIT 1)),
        cd_current_date,
        (SELECT parcel_id FROM relationship where id = valid_relationship_id),
        (SELECT party_id FROM relationship where id = valid_relationship_id),
        (SELECT geom FROM relationship where id = valid_relationship_id),
        (SELECT tenure_type FROM relationship where id = valid_relationship_id),
        (SELECT acquired_date FROM relationship where id = valid_relationship_id),
        (SELECT how_acquired FROM relationship where id = valid_relationship_id))
        RETURNING id INTO rh_id;

        -- Deactivate all older versions
        UPDATE relationship_history SET active = false WHERE relationship_id = valid_relationship_id AND version < cd_new_version;

        RETURN rh_id;

    ELSE
        RAISE EXCEPTION 'Cannot increment version';
    END IF;

END;
$$ LANGUAGE plpgsql VOLATILE;