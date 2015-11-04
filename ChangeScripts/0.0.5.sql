/******************************************************************
Change Script 0.0.5
Date: 11/2/15

    1. Add new fields to relationship_history & show_relationships view
    2. New update relationship function
    3. Add new fields to cd_create_relationship's add history statements
    4. Remove parents from parcel history
    5. Add relationship history to activity view
    6. Add group_name to show_relationships view
    7. Show relationship history area & length of show_relationship_history view

******************************************************************/
DROP TABLE relationship_geometry CASCADE;

ALTER TABLE relationship ADD COLUMN geom geometry;
ALTER TABLE relationship ADD COLUMN length numeric;
ALTER TABLE relationship ADD COLUMN area numeric;
ALTER TABLE relationship_history DROP COLUMN geom_id CASCADE;
ALTER TABLE relationship_history ADD COLUMN geom geometry;
ALTER TABLE relationship_history ADD COLUMN length numeric;
ALTER TABLE relationship_history ADD COLUMN area numeric;

CREATE OR replace view show_relationship_history AS
SELECT
project.id as project_id,
-- relationship history columns
rh.relationship_id, rh.origin_id, rh.version, rh.parent_id, rh.geom, rh.tenure_type, rh.acquired_date, rh.how_acquired,
parcel.id AS parcel_id, t.type as relationship_type,
rh.expiration_date, rh.description, rh.date_modified, rh.active, rh.time_created, rh.length, rh.area,
rh.time_updated, rh.created_by, rh.updated_by,
-- relationship table columns
s.type AS spatial_source, party.id AS party_id, first_name, last_name
FROM parcel,party,relationship r, spatial_source s, tenure_type t, relationship_history rh, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND rh.relationship_id = r.id
AND parcel.spatial_source = s.id
AND rh.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

CREATE OR replace view show_relationships AS
SELECT r.id AS id, t.type AS tenure_type, r.how_acquired, r.acquired_date, parcel.id AS parcel_id, project.id AS project_id,s.type AS spatial_source, r.geom,
party.id AS party_id, first_name, lASt_name, group_name, r.time_created,r.active, r.time_updated
FROM parcel,party,relationship r, spatial_source s, tenure_type t, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

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
SELECT 'party', party.id, NULL, COALESCE(first_name || ' ' || lASt_name, group_name), NULL, party.time_created, party.project_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, COALESCE(p.first_name || ' ' || p.lASt_name, p.group_name) AS owners, par.id::text AS parcel_id, r.time_created, r.project_id
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
s.type AS spatial_source, party.id AS party_id, first_name, last_name
FROM parcel,party,relationship r, spatial_source s, tenure_type t, relationship_history rh, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND rh.relationship_id = r.id
AND parcel.spatial_source = s.id
AND rh.tenure_type = t.id
AND r.project_id = project.id;

DROP VIEW show_relationships;
CREATE OR replace view show_relationships AS
SELECT r.id AS id, t.type AS tenure_type, r.how_acquired, r.acquired_date, parcel.id AS parcel_id, project.id AS project_id,s.type AS spatial_source, r.geom,
party.id AS party_id, first_name, lASt_name, r.time_created,r.active, r.time_updated
FROM parcel,party,relationship r, spatial_source s, tenure_type t, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;


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


/******************************************************************

 cd_create_relationship

-- Create relationship with relationship geometry

SELECT * FROM cd_create_relationship(1,7,null,4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'lease',current_date,'stolen','family fortune');
SELECT * FROM cd_create_relationship(1,3,null,4,$anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'lease',current_date,null,null);

select * from relationship_history where relationship_id = 18
select * from relationship where id = 18

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
