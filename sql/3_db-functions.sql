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
    cd_cd_create_party

    Create new party

    -- Create new party Ian O'Guin for project 1
    SELECT * FROM cd_create_party(1, 'Ian', 'O''Guin', null);
    -- Create new party group Wal Mart for project 1
    SELECT * FROM cd_create_party(1, null, null, 'Wal-Mart');


******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_party(project_id int, first_name character varying, last_name character varying, cd_group_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
BEGIN

    IF $1 IS NOT NULL AND (($2 IS NOT NULL AND $3 IS NOT NULL) OR ($4 IS NOT NULL)) THEN

        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, first_name, last_name, group_name) VALUES (cd_project_id,first_name,last_name, cd_group_name) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RETURN p_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


/********************************************************

    cd_create_parcel

    INSERT INTO organization (title) VALUES ('HFH');
    INSERT INTO project (organization_id, title) VALUES ((SELECT id from organization where title = 'HFH'), 'Bolivia');

    select * from parcel
    select * from project

    SELECT ST_LENGTH(ST_TRANSFORM((select geom from parcel where id =20),3857))
    SELECT ST_GeometryType((select geom from parcel where id =20))
    select * from parcel

-- SELECT * FROM cd_create_parcel('survey_sketch','11', 1 ,(select geom from parcel where id = 7),null,null,'new description');
-- select * from parcel
-- select * from parcel_history

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_parcel(spatial_source character varying,
                                            ckan_user_id integer,
                                            project_id integer,
                                            geom geometry,
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
  cd_user_id int;
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_gov_pin character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- spatial source and ckan id required
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

        SELECT INTO cd_project_id id FROM project where id = $3;

        IF cd_project_id IS NOT NULL THEN
            SELECT INTO cd_current_date * FROM current_date;

            cd_gov_pin := gov_pin;
            cd_land_use := land_use;
            cd_spatial_source = spatial_source;
            cd_history_description = history_description;
            cd_user_id = ckan_user_id::int;
            cd_geometry = geom;

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
				    INSERT INTO parcel (spatial_source,project_id, user_id,geom,area,length,land_use,gov_pin,created_by) VALUES
				    (cd_spatial_source_id,cd_project_id,cd_user_id,cd_geometry,cd_area,cd_length,cd_land_use,cd_gov_pin,cd_user_id) RETURNING id INTO p_id;
				    RAISE NOTICE 'Successfully created parcel, id: %', p_id;

				    INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified,created_by) VALUES
				    (p_id,p_id,cd_history_description,cd_current_date,cd_user_id) RETURNING id INTO ph_id;
				    RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;
		    ELSE
		        RAISE NOTICE 'Invalid spatial source';
		    END IF;

	        IF p_id IS NOT NULL THEN
		        RETURN p_id;
	        ELSE
		        RAISE NOTICE 'Unable to create Parcel';
		        RETURN NULL;
	        END IF;
	    ELSE
	        RAISE NOTICE 'Invalid project id';
	        RETURN NULL;
	    END IF;

	ELSE
	    RAISE NOTICE 'The following parameters are required: spatial_source, ckan_user_id, geom_type';
	    RAISE NOTICE 'spatial_source:%  ckan_user_id:% ', $1, $2;
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


/******************************************************************

 cd_create_relationship

 select * from relationship
 select * from parcel
 select * from person
 select * from project
 select * from current_date
 -- Add person (id: 4) & parcel (id: 7) to relationship
 SELECT * FROM cd_create_relationship(1,7,null,4,null,'lease',null,'Uncle Phils will',null);
 -- with date
 SELECT * FROM cd_create_relationship(1,7,null,4,null,'lease',current_date,null,null);

******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_relationship(
                                            project_id int,
                                            parcel_id int,
                                            ckan_user_id int,
                                            party_id int,
                                            geom_id int,
                                            tenure_type character varying,
                                            acquired_date date,
                                            how_acquired character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  r_id integer;

  cd_parcel_id int;
  cd_ckan_user_id int;
  cd_party_id int;
  cd_project_id int;
  cd_geom_id int;
  cd_tenure_type_id int;
  cd_tenure_type character varying;
  cd_acquired_date date;
  cd_how_acquired character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $4 IS NOT NULL AND $6 IS NOT NULL THEN

        cd_history_description = history_description;
        cd_tenure_type = tenure_type;

        cd_acquired_date = acquired_date;

	    -- get parcel_id
        SELECT INTO cd_parcel_id id FROM parcel where id = parcel_id::int;
        -- get party_id
        SELECT INTO cd_party_id id FROM party where id = party_id::int;
        -- get tenure type id
        SELECT INTO cd_tenure_type_id id FROM tenure_type where type = cd_tenure_type;
        -- get project id
        SELECT INTO cd_project_id id FROM project where id = $1;
        -- get geom id
        SELECT INTO cd_geom_id id FROM relationship_geometry where id = $5;

        -- get ckan user id
        cd_ckan_user_id = ckan_user_id;

        SELECT INTO cd_current_date * FROM current_date;

        IF cd_parcel_id IS NOT NULL AND cd_tenure_type_id IS NOT NULL AND cd_project_id IS NOT NULL THEN

            RAISE NOTICE 'Relationship parcel_id: %', cd_parcel_id;

            IF cd_party_id IS NULL THEN
                RAISE NOTICE 'Relationship must have a party id';
                RETURN NULL;

            ELSIF cd_party_id IS NOT NULL THEN
                RAISE NOTICE 'Relationship party_id: %', cd_party_id;

		        -- create relationship row
                INSERT INTO relationship (project_id,created_by,parcel_id,party_id,tenure_type,geom_id,acquired_date,how_acquired)
                VALUES (cd_project_id,ckan_user_id,cd_parcel_id,cd_party_id, cd_tenure_type_id, cd_geom_id, cd_acquired_date,how_acquired) RETURNING id INTO r_id;

                -- create relationship history
                INSERT INTO relationship_history (relationship_id,origin_id,active,description,date_modified, created_by)
                VALUES (r_id,r_id,true,'History', cd_current_date, cd_ckan_user_id);

		        RAISE NOTICE 'Successfully created new relationship id: %', r_id;

            END IF;
        ELSE
            RAISE NOTICE 'Invalid parcel id:% or tenure type: % or project_id %', cd_parcel_id, cd_tenure_type_id, cd_project_id;
            RETURN NULL;
        END IF;

        RETURN r_id;

	ELSE
	    RAISE NOTICE 'The following parameters are required: cd_parcel_id, tenure_type, & party_id';
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

  -- TODO get real user id from CKAN
  data_ckan_user_id = 11;

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
          SELECT INTO data_person_id * FROM cd_create_party (data_project_id, data_survey_first_name,data_survey_last_name, null);
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
              WHEN ('_geolocation') THEN
                RAISE NOTICE 'Found geolocation:' ;
                  data_geojson = element.value::text;

                  RAISE NOTICE 'geojson: %', data_geojson;

                  SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326); -- convert to LAT LNG GEOM

                  RAISE NOTICE 'GEOLOCATION VALUE %: ', data_geom;

		   -- Create new parcel
                  SELECT INTO data_parcel_id * FROM cd_create_parcel('survey_sketch','11',data_project_id,data_geom,null,null,'new description');

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

-- Create new organization
/********************************************************

    cd_create_organization

    select * from organization;

    SELECT * FROM cd_create_organization('Cadasta','Cadasta Org',null);
    SELECT * FROM cd_create_organization('Cadasta',null,null);

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_organization(ckan_org_id character varying, title character varying, description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer;
  cd_ckan_org_id character varying;
  cd_description character varying;
  cd_title character varying;
BEGIN

    cd_ckan_org_id = ckan_org_id;
    cd_description = description;
    cd_title = title;

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

	    -- Save the original organization ID variable
        INSERT INTO organization (title, description, ckan_id) VALUES (cd_title,cd_description,cd_ckan_org_id) RETURNING id INTO o_id;

	    RETURN o_id;
    ELSE
        RAISE NOTICE 'Missing ckan_org_id OR title';
        RETURN o_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


-- Create new project

/********************************************************

    cd_create_project

    select * from project;
    select * from organization;

    SELECT * FROM cd_create_project(1,'Medellin','Medellin Pilot');
    SELECT * FROM cd_create_project(1,'Ghana','Ghana Pilot');

    SELECT * FROM cd_create_project(2,'Ghana',null);
    SELECT * FROM cd_create_project(4,'Medellin','Medellin Pilot');

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_project(org_id integer, ckan_project_id character varying, title character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  o_id integer;
  cd_ckan_project_id character varying;
  cd_title character varying;
BEGIN

    cd_ckan_project_id = ckan_project_id;
    cd_title = title;
    cd_ckan_project_id = regexp_replace(ckan_project_id, U&'\2028', '', 'g');

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        -- Grab org id from org table
        SELECT INTO o_id id FROM organization WHERE id = $1;

        -- Validate organization id
        IF o_id IS NOT NULL AND cd_validate_organization($1) THEN

	        -- Create project and store project id
            INSERT INTO project (organization_id, ckan_id, title) VALUES (o_id,cd_ckan_project_id,cd_title) RETURNING id INTO p_id;

            RETURN p_id;
        ELSE
            RAISE NOTICE 'Invalid organization id %', $1;
            RETURN p_id;
        END IF;

    ELSE
        RAISE NOTICE 'All parameters required';
        RETURN p_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


-- Create new resource
/********************************************************

    cd_create_resource

    SELECT * FROM cd_create_resource(1,'parcel',2,'http://www.cadasta.org/2/parcel',null);

    SELECT * FROM cd_create_resource(1,'party',2,'http://www.cadasta.org/2/party',null);

    SELECT * FROM cd_create_resource(1,'parcel',16,'http://www.cadasta.org/16/party',null, 'daniel-home');

    SELECT * FROM cd_create_resource(1,'relationship',4,'http://www.cadasta.org/4/relationship',null);

    select * from resource
    select * from resource_parcel
    select * from resource_party
    select * from resource_relationship

    select * from party
    select * from relationship

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_resource(project_id int, resource_type character varying, resource_type_id integer, url character varying, description character varying, filename character varying)
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
    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL AND $4 IS NOT NULL THEN

        -- validate project id
        SELECT INTO p_id id FROM project WHERE id = $1;

        IF cd_validate_project(p_id) THEN

                CASE lower(resource_type)
                    -- ensure resource type is supported
                    WHEN 'parcel' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM parcel WHERE id = resource_type_id;

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
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid parcel id';
                            RETURN r_id;
                        END IF;
                    WHEN 'party' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM party WHERE id = resource_type_id;

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
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid party id';
                            RETURN r_id;
                        END IF;
                    WHEN 'relationship' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM relationship WHERE id = resource_type_id;

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
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid relationship id';
                            RETURN r_id;
                        END IF;
                ELSE
                    RAISE NOTICE 'Invalid resource type';
                    RETURN r_id;
                END CASE;

        ELSE
            RAISE NOTICE 'Invalid project id';
            RETURN r_id;
        END IF;
    ELSE
        RAISE NOTICE 'project_id, resource_type, and url are required';
        RETURN r_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;