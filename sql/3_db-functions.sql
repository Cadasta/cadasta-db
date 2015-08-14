/******************************************************************
    Create New field data form

    cd_create_field_data

******************************************************************/

-- Create new Field Data

DROP FUNCTION IF EXISTS cd_create_field_data(id_string character varying);

CREATE OR REPLACE FUNCTION cd_create_field_data(id_string character varying)
  RETURNS INTEGER AS $$
  DECLARE
  s_id integer;
  field_data_id_string character varying;
BEGIN

    field_data_id_string = id_string;

    IF field_data_id_string IS NOT NULL THEN
	-- Create survey and return survey id
    INSERT INTO field_data (id_string) VALUES (field_data_id_string) RETURNING id INTO s_id;

	RETURN s_id;

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
CREATE OR REPLACE FUNCTION cd_import_data_json(field_data_id int, json_string character varying)
RETURNS BOOLEAN AS $$
DECLARE
  raw_data_id int;
  rec record;
BEGIN

  IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

    INSERT INTO raw_data (field_data_id, json) VALUES (field_data_id,json_string::json) RETURNING id INTO raw_data_id;

    IF raw_data_id IS NOT NULL THEN
        RAISE NOTICE 'Succesfully inserted raw json data, id: %', raw_data_id;
        RETURN TRUE;
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

******************************************************************/

-- Create new party

DROP FUNCTION IF EXISTS cd_create_party(first_name character varying, last_name character varying);

CREATE OR REPLACE FUNCTION cd_create_party(first_name character varying, last_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
	-- Save the original organization ID variable
    INSERT INTO party (first_name, last_name) VALUES (first_name,last_name) RETURNING id INTO p_id person_id;

	RETURN p_id;

	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;



/******************************************************************
    cd_create_parcel

    Create New Parcel

    -- SELECT * FROM cd_create_parcel ('survey_sketch',5,222.45,'point',null,null,'62.640826','-114.233223',null,null,'just got this yesterday');
    -- select * from parcel
    -- select * from parcel_history

******************************************************************/

-- SELECT * FROM cd_create_parcel ('survey_sketch',5,222.45,'point',null,null,'62.640826','-114.233223',null,null,'just got this yesterday');
-- select * from parcel
-- select * from parcel_history

DROP FUNCTION IF EXISTS cd_create_parcel(spatial_source character varying,ckan_user_id integer,area numeric,geom_type character varying,line geometry,
polygon geometry,lat numeric,lng numeric,land_use land_use,gov_pin character varying);

CREATE OR REPLACE FUNCTION cd_create_parcel(spatial_source character varying,
                                            ckan_user_id integer,
                                            area numeric,
                                            geom_type character varying,
                                            geom geometry,
                                            lat numeric,
                                            lng numeric,
                                            land_use land_use,
                                            gov_pin character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  ph_id integer;
  geometry geometry;

  cd_geometry_type character varying;
  cd_parcel_timestamp timestamp;
  cd_user_id int;
  cd_area numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_gov_pin character varying;
  cd_lat numeric;
  cd_lng numeric;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- geometry is not required at first
    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $4 IS NOT NULL AND ($5 IS NOT NULL OR ($6 IS NOT NULL AND $7 IS NOT NULL)) THEN

        -- get time
        SELECT INTO cd_parcel_timestamp * FROM localtimestamp;

        -- get geom
        SELECT INTO cd_geometry_type * FROM initcap(geom_type);

        SELECT INTO cd_current_date * FROM current_date;

        cd_lat := lat::numeric;
        cd_lng := lng::numeric;
        cd_area := area::numeric;
        cd_gov_pin := gov_pin;
        cd_land_use := land_use;
        cd_spatial_source = spatial_source;
        cd_history_description = history_description;
        cd_user_id = ckan_user_id::int;

        SELECT INTO cd_spatial_source_id id FROM spatial_source WHERE type = cd_spatial_source;

	    IF cd_spatial_source IS NOT NULL THEN

	    IF cd_geometry_type IS NOT NULL THEN
	        -- get geom type
	        IF cd_geometry_type ='Polygon' THEN
			cd_geometry_type = '';
		ELSIF cd_geometry_type = 'Point' AND cd_lat IS NOT NULL AND cd_lng IS NOT NULL THEN

			SELECT INTO geometry * FROM ST_SetSRID(ST_MakePoint(cd_lat, cd_lng),4326);

			RAISE NOTICE 'GEOM: %', geometry;

			IF geometry IS NOT NULL THEN
				INSERT INTO parcel (spatial_source,user_id,geom,area,land_use,gov_pin,created_by) VALUES
				(cd_spatial_source_id,cd_user_id, geometry,cd_area,cd_land_use,cd_gov_pin,cd_user_id) RETURNING id INTO p_id;
				RAISE NOTICE 'Successfully created parcel, id: %', p_id;

				INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified,created_by) VALUES
				(p_id,p_id,cd_history_description,cd_current_date,cd_user_id) RETURNING id INTO ph_id;
				RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;

			ELSE
				RAISE NOTICE 'Geometry is required';
				RETURN NULL;
			END IF;
		END IF;

		END IF;

	    ELSE
		RAISE NOTICE 'Geometry Type is required. (Point, Polygon, or Line)';
		RETURN NULL;
	    END IF;

	    IF p_id IS NOT NULL THEN
		RETURN p_id;
	    ELSE
		RAISE NOTICE 'Unable to create Parcel';
		RETURN NULL;
	    END IF;

	ELSE
	    RAISE NOTICE 'The following parameters are required: spatial_source, ckan_user_id, geom_type';
	    RAISE NOTICE '1:%  2:%  3:%  4:%  5%:  :6%  :7%   8:%  9:%  10:% ', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;


-- SELECT * FROM cd_create_relationship(7,5,2,2,NULL,'Own',null,null,null);
-- select * from parcel
-- select * from relationship

/******************************************************************
 TESTING cd_create_relationship

 select * from relationship
 select * from parcel
 select * from person

 select * from current_date


 -- Add person & parcel to relationship
 SELECT * FROM cd_create_relationship(7,5,4,null,null,'lease',null,null,null);
 SELECT * FROM cd_create_relationship(5,1,3,null,NULL,'Own','2001-09-28','Stolen',false);

 SELECT * FROM cd_create_relationship(7,5,2,2,NULL,'Own',null,null,null);
 SELECT * FROM cd_create_relationship(7,5,2,2,NULL,'Own',null,null,null);
******************************************************************/

DROP FUNCTION IF EXISTS cd_create_relationship(parcel_id int,ckan_user_id integer,party_id int,geom_id int,
tenure_type character varying,acquired_date character varying,how_acquired character varying,archived boolean,history_description character varying);

CREATE OR REPLACE FUNCTION cd_create_relationship(
                                            parcel_id int,
                                            ckan_user_id int,
                                            party_id int,
                                            geom_id int,
                                            tenure_type character varying,
                                            acquired_date date,
                                            how_acquired character varying,
                                            archived boolean,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  r_id integer;

  cd_parcel_id int;
  cd_ckan_user_id int;
  cd_party_id int;
  cd_geom_id int;
  cd_tenure_type_id int;
  cd_tenure_type character varying;
  cd_acquired_date date;
  cd_how_acquired character varying;
  cd_archived boolean;
  cd_history_description character varying;
  cd_relationship_timestamp timestamp;
  cd_current_date date;

BEGIN

    IF $1 IS NOT NULL AND $5 IS NOT NULL AND ($3 IS NOT NULL) THEN

        cd_history_description = history_description;

	    -- capitalize tenture type
	    SELECT INTO cd_tenure_type * FROM initcap(tenure_type);
	    -- get timestamp
	    SELECT INTO cd_relationship_timestamp * FROM localtimestamp;
	    -- get parcel_id
        SELECT INTO cd_parcel_id id FROM parcel where id = parcel_id::int;
        -- get party_id
        SELECT INTO cd_party_id id FROM party where id = party_id::int;
        -- get tenure type id
        SELECT INTO cd_tenure_type_id id FROM tenure_type where type = cd_tenure_type;
        -- get ckan user id
        cd_ckan_user_id = ckan_user_id;

        SELECT INTO cd_current_date * FROM current_date;


        IF cd_parcel_id IS NOT NULL AND cd_tenure_type_id IS NOT NULL THEN

            RAISE NOTICE 'Relationship parcel_id: %', cd_parcel_id;

            IF cd_party_id IS NULL THEN
                RAISE NOTICE 'Relationship must have a party id';
                RETURN NULL;

            ELSIF cd_party_id IS NOT NULL THEN
                RAISE NOTICE 'Relationship party_id: %', cd_party_id;

		        -- create relationship row
                INSERT INTO relationship (created_by,parcel_id,party_id,tenure_type,geom_id,acquired_date,how_acquired, archived)
                VALUES (ckan_user_id,cd_parcel_id,cd_party_id, cd_tenure_type_id, cd_geom_id, cd_acquired_date,cd_how_acquired,cd_archived) RETURNING id INTO r_id;

                -- create relationship history
                INSERT INTO relationship_history (relationship_id,origin_id,active,description,date_modified, created_by)
                VALUES (r_id,cd_parcel_id,true,'History', cd_current_date, cd_ckan_user_id);

		        RAISE NOTICE 'Successfully created new relationship id: %', r_id;

--            ELSIF cd_group_id IS NOT NULL AND cd_party_id IS NULL THEN
--                -- create relationship row
--                INSERT INTO relationship (parcel_id,party_id,group_id,tenure_type,geom_id,acquired_date,how_acquired, archived)
--                VALUES (cd_parcel_id,cd_party_id, cd_group_id, cd_tenure_type_id, cd_geom_id, cd_acquired_date,cd_how_acquired,cd_archived) RETURNING id INTO r_id;
--                RAISE NOTICE 'Successfully created new relationship id: %', r_id;
--
--                -- create relationship history
--                INSERT INTO relationship_history (relationship_id,origin_id,active,timestamp,description,date_modified)
--                VALUES (r_id,r_id,true,cd_relationship_timestamp, cd_history_description, cd_current_date);
            END IF;
        ELSE
            RAISE NOTICE 'Invalid parcel id or tenure type';
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
  raw_data_id integer;
  raw_field_data_id integer;
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
            SELECT INTO question_id id FROM question WHERE lower(name) = lower(question_slug) AND field_data_id = raw_field_data_id AND group_id = (select id from "q_group" where lower(name) = lower(parent_question_slug) and field_data_id = raw_field_data_id);
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
                data_tenure_type = 'Own';
              WHEN 'freehold' THEN
                data_tenure_type = 'Own';
              WHEN 'lease' THEN
                data_tenure_type = 'Lease';
              WHEN 'common_law_freehold' THEN
                data_tenure_type = 'Own';
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
                SELECT INTO point replace(regexp_replace(element.value, '"|,|\[|\]', '', 'g'), '-', ' -');
--                SELECT INTO point replace(point,'-',' -');

                -- RAISE NOTICE 'point: %', point;
                x := substring(point, 0, position(' ' in point))::numeric;
                y := substring(point, (position(' ' in point)+1), char_length(point))::numeric;
                 RAISE NOTICE 'x: %', x;
                 RAISE NOTICE 'y: %', y;
                IF point IS NOT NULL AND point <> 'null null' THEN

                  -- Geom type is point
                  data_geom_type = 'Point';

                  -- Create new parcel with lat lng as geometry
                  SELECT INTO data_parcel_id * FROM cd_create_parcel ('survey_grade_gps','11',null,data_geom_type,null,y,x,null,null,'new description');
                  RAISE NOTICE 'New parcel id: %', data_parcel_id;

                  -- set new parcel id in survey table
                  -- UPDATE field_data SET parcel_id = data_parcel_id WHERE id = raw_field_data_id;
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
      IF raw_field_data_id IS NOT NULL THEN
        EXECUTE 'UPDATE response SET field_data_id = ' || quote_literal(raw_field_data_id) || ' WHERE respondent_id = ' || data_respondent_id;
      END IF;
      IF data_parcel_id IS NOT NULL AND data_person_id IS NOT NULL THEN
        -- create relationship

        SELECT INTO data_relationship_id * FROM cd_create_relationship
        (data_parcel_id,data_ckan_user_id,data_person_id,null,data_tenure_type,data_date_land_possession, data_means_aquired, false, null);

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
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();