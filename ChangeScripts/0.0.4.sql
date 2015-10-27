/******************************************************************
Change Script 0.0.4
Date: 10/20/15

    1. Alter pacel_history table
    2. Add cd_update_parcel function
    3. Update cd_create_parcel function
    4. Add parcel history to show_activity view

******************************************************************/

ALTER TABLE parcel_history ADD CONSTRAINT parcel_history_origin_id_fkey FOREIGN KEY (origin_id) REFERENCES parcel (id) MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;

ALTER TABLE parcel_history ADD COLUMN spatial_source int references spatial_source(id);
ALTER TABLE parcel_history ADD COLUMN user_id character varying;
ALTER TABLE parcel_history ADD COLUMN area numeric;
ALTER TABLE parcel_history ADD COLUMN length numeric;
ALTER TABLE parcel_history ADD COLUMN geom geometry;
ALTER TABLE parcel_history ADD COLUMN land_use land_use;
ALTER TABLE parcel_history ADD COLUMN gov_pin character varying;


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

/********************************************************

    cd_update_parcel

    select * from parcel_history where parcel_id = 3

    SELECT NOT(ST_Equals((SELECT geom FROM parcel_history where id = 14), (select geom from parcel_history where id = 15)))

    -- Update parcel geom, spatial_source, land_use, gov_pin and description
    SELECT * FROM cd_update_parcel (3, 13, $anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'digitized',
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
                parcel_id, origin_id, parent_id, version, description, date_modified,
                spatial_source, user_id, area, length, geom, land_use, gov_pin)
	            VALUES (p_id, p_id, (SELECT parent_id FROM parcel_history where parcel_id = p_id ORDER BY version DESC LIMIT 1), cd_new_version, COALESCE(cd_description,(SELECT description FROM parcel_history where parcel_id = p_id GROUP BY description, version ORDER BY version DESC LIMIT 1)), cd_current_date,
                (SELECT spatial_source FROM parcel WHERE id = p_id), (SELECT user_id FROM parcel WHERE id = p_id), cd_area, cd_length, cd_geom,
                (SELECT land_use FROM parcel WHERE id = p_id), (SELECT gov_pin FROM parcel WHERE id = p_id)) RETURNING id INTO ph_id;
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


DROP VIEW show_activity;

CREATE OR replace view show_activity AS
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
SELECT 'party', party.id, NULL, first_name || ' ' || lASt_name, NULL, party.time_created, party.project_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, p.first_name || ' ' || p.lASt_name AS owners, par.id::text AS parcel_id, r.time_created, r.project_id
FROM relationship r, tenure_type t, party p, parcel par, project pro
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id
AND r.project_id = pro.id)
AS foo
Order BY time_created DESC;