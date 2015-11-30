/******************************************************************
Change Script 0.0.9
Date: 11/11/15

    1. Add GIST indicies to all geometry tables
    2. Update tenure types
    3. Change first_name/last_name to full name on db functions and veiws
    4. New show_field_data_responses view
    5. Update process data trigger tenure types and create party call

******************************************************************/

CREATE INDEX idx_parcel_geom ON parcel USING GIST (geom);
CREATE INDEX idx_parcel_history_geom ON parcel_history USING GIST (geom);
CREATE INDEX idx_relationship_geom ON relationship USING GIST (geom);
CREATE INDEX idx_relationship_history_geom ON relationship_history USING GIST (geom);
CREATE INDEX idx_project_extents_geom ON project_extents USING GIST (geom);

TRUNCATE TABLE tenure_type CASCADE;
ALTER TABLE field_data DROP COLUMN parcel_id CASCADE;
ALTER TABLE response DROP COLUMN validated CASCADE;

ALTER TABLE respondent ADD COLUMN validated boolean DEFAULT false;

INSERT INTO tenure_type (type) VALUES ('indigenous land rights');
INSERT INTO tenure_type (type) VALUES ('joint tenancy');
INSERT INTO tenure_type (type) VALUES ('tenancy in common');
INSERT INTO tenure_type (type, description) VALUES ('undivided co-ownership','general term covering strata title and condominiums');
INSERT INTO tenure_type (type) VALUES ('easement');
INSERT INTO tenure_type (type) VALUES ('equitable servitude');
INSERT INTO tenure_type (type, description) VALUES ('mineral rights', 'includes oil & gas');
INSERT INTO tenure_type (type, description) VALUES ('water rights', 'collective term for bundle of rights possible');
INSERT INTO tenure_type (type, description) VALUES ('concessionary rights','non-mineral');
INSERT INTO tenure_type (type) VALUES ('carbon rights');

ALTER TABLE respondent ADD COLUMN parcel_id int references parcel(id);
ALTER TABLE respondent ADD COLUMN party_id int references party(id);
ALTER TABLE respondent ADD COLUMN relationship_id int references relationship(id);

ALTER TABLE party ADD COLUMN full_name character varying;
ALTER TABLE party DROP COLUMN first_name CASCADE;
ALTER TABLE party DROP COLUMN last_name CASCADE;
ALTER TABLE party DROP CONSTRAINT party_check;

TRUNCATE TABLE party CASCADE;
ALTER TABLE party
  ADD CONSTRAINT party_check CHECK (full_name IS NOT NULL OR group_name IS NOT NULL);

DROP FUNCTION cd_create_party(integer, party_type, character varying, character varying, character varying, character varying, date, character varying, character varying);
DROP FUNCTION cd_update_party(integer, integer, party_type, character varying, character varying, character varying, character varying, date, character varying, character varying);

CREATE OR REPLACE VIEW show_field_data_responses AS
select f.project_id, r.field_data_id, r.respondent_id, r.question_id, r.text, r.time_created, r.time_updated
from response r , field_data f
where r.field_data_id = f.id;

DROP VIEW show_parties;
CREATE OR REPLACE VIEW show_parties AS
select pro.id as project_id, p.id, count(r.id) as num_relationships, p.group_name, full_name, type,  p.national_id, p.gender, p.dob, p.description as notes, p.active, p.time_created, p.time_updated
from party p left join relationship r on r.party_id = p.id, project pro
where p.project_id = pro.id
group by p.id, pro.id;

DROP VIEW show_relationships;
CREATE OR replace view show_relationships AS
SELECT r.id AS id, t.type AS tenure_type, r.how_acquired, r.acquired_date, parcel.id AS parcel_id, project.id AS project_id,s.type AS spatial_source, r.geom,
party.id AS party_id, full_name, group_name, r.time_created,r.active, r.time_updated
FROM parcel,party,relationship r, spatial_source s, tenure_type t, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

DROP VIEW show_activity;
-- Show latest parcel, party, & relationship activity
CREATE OR REPLACE VIEW show_activity AS
SELECT * FROM
(SELECT 'parcel' AS activity_type, parcel.id, s.type, NULL AS name,NULL AS parcel_id, parcel.time_created, parcel.project_id
FROM parcel, spatial_source s, project
WHERE parcel.spatial_source = s.id
AND parcel.project_id = project.id
UNION all
SELECT 'parcel_history' AS activity_type, ph.parcel_id, s.type, NULL AS name,NULL AS parcel_id, ph.time_created, p.project_id
FROM parcel_history ph, spatial_source s, project ,parcel p
WHERE ph.spatial_source = s.id
AND p.project_id = project.id
AND ph.parcel_id = p.id
AND version > 1
UNION all
SELECT 'party', party.id, NULL, COALESCE(full_name, group_name), NULL, party.time_created, party.project_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, COALESCE(p.full_name, p.group_name) AS owners, par.id::text AS parcel_id, r.time_created, r.project_id
FROM relationship r, tenure_type t, party p, parcel par, project pro
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id
AND r.project_id = pro.id
UNION ALL
SELECT 'relationship_history' AS activity_type, r.id, t.type, NULL AS name,NULL AS parcel_id, rh.time_created, r.project_id
FROM relationship_history rh, tenure_type t, project, relationship r
WHERE rh.tenure_type = t.id
AND rh.relationship_id = r.id
AND r.project_id = project.id
AND version > 1)
AS foo
Order BY time_created DESC;

DROP VIEW show_relationship_history;
CREATE OR replace view show_relationship_history AS
SELECT
project.id as project_id,
-- relationship history columns
rh.relationship_id, rh.origin_id, rh.version, rh.parent_id, rh.geom, rh.tenure_type, rh.acquired_date, rh.how_acquired,
parcel.id AS parcel_id, t.type as relationship_type,
rh.expiration_date, rh.description, rh.date_modified, rh.active, rh.time_created, rh.length, rh.area,
rh.time_updated, rh.created_by, rh.updated_by,
-- relationship table columns
s.type AS spatial_source, party.id AS party_id, full_name, group_name
FROM parcel,party,relationship r, spatial_source s, tenure_type t, relationship_history rh, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND rh.relationship_id = r.id
AND parcel.spatial_source = s.id
AND rh.tenure_type = t.id
AND r.project_id = project.id;


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

/******************************************************************
    cd_create_party

    -- Create new party Ian O'Guin for project 1
    SELECT * FROM cd_create_party(1, 'individual', 'Ian', null, 'Male', '4-25-1990', 'my name is Ian', '14u1oakldaCCCC');

    -- Create new party group Wal Mart for project 1
    SELECT * FROM cd_create_party(1, 'group', null, 'Wal-Mart', null, null, null, null);

    -- FAIL: Add a group with a full name
    SELECT * FROM cd_create_party(1, 'group', 'Daniel Baah', 'Wal-Mart', null, null, null, null);


******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_party(project_id int,
                                            cd_party_type party_type,
                                            full_name character varying,
                                            cd_group_name character varying,
                                            cd_gender character varying,
                                            cd_dob date,
                                            cd_description character varying,
                                            cd_national_id character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
  cd_party_type_lower character varying;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND (($3 IS NOT NULL) OR ($4 IS NOT NULL)) THEN

        IF ($3 IS NOT NULL AND $4 IS NOT NULL) THEN
            RAISE EXCEPTION 'Cannot have an individual and group name';
        END IF;


        IF ($3 IS NOT NULL AND $2 = 'group') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;

        IF ($4 IS NOT NULL AND $2 = 'individual') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;

        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, type, full_name, group_name, gender, dob, description, national_id)
        VALUES (cd_project_id, cd_party_type, full_name, cd_group_name, cd_gender, cd_dob, cd_description, cd_national_id) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RAISE EXCEPTION 'project_id, party_type , full_name OR group_name required';
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;




/********************************************************

    cd_update_party
    
    -- Update party 1 - Change to group, set group_name to Walmart
    SELECT * FROM cd_update_party(1,21,'group',null,'Walmart',null,null,'group description','xxx661222x');

    -- Update party 2 - Change to individual, set name to Sam Hernandez
    SELECT * FROM cd_update_party(1,21,'individual','Sam',null,'free text gender','1990-04-25','individual description','xxx661222x');

*********************************************************/

CREATE OR REPLACE FUNCTION cd_update_party( cd_project_id int,
                                            cd_party_id int,
                                            cd_party_type party_type,
                                            cd_full_name character varying,
                                            cd_group_name character varying,
                                            cd_gender character varying,
                                            cd_dob date,
                                            cd_description character varying,
                                            cd_national_id character varying)
  RETURNS INTEGER AS $$
  DECLARE
  valid_party_id int;
BEGIN

    IF NOT(SELECT * FROM cd_validate_project(cd_project_id)) THEN
        RAISE EXCEPTION 'Invalid project id: %', cd_project_id;
    END IF;

    SELECT INTO valid_party_id id FROM party WHERE id = cd_party_id AND project_id = cd_project_id;

    IF NOT(SELECT * FROM cd_validate_party(valid_party_id)) THEN
        RAISE EXCEPTION 'Invalid party id';
    END IF;

    IF $3 = 'individual' AND cd_full_name IS NULL THEN
	RAISE EXCEPTION 'Party type individual must have full name';
    END IF;

    IF ($4 IS NOT NULL AND $3 = 'group') OR  ($3 = 'group' AND cd_group_name IS NULL) THEN
	RAISE EXCEPTION 'Party type group must have group name and no full name';
    END IF;

    -- Ensure one attribute is updated
    IF $3 IS NOT NULL OR $4 IS NOT NULL OR $5 IS NOT NULL OR $6 IS NOT NULL OR $7 IS NOT NULL OR $8 IS NOT NULL OR $9 IS NOT NULL THEN
	
        UPDATE party
        SET
        type = cd_party_type,
        full_name = cd_full_name,
        group_name = cd_group_name,
        gender = cd_gender,
        dob = cd_dob,
        description = cd_description,
        national_id = cd_national_id
        WHERE id = valid_party_id;

        RETURN valid_party_id;

    ELSE 
	RAISE EXCEPTION 'All values are null';
    END IF;


END;
  $$ LANGUAGE plpgsql VOLATILE;
