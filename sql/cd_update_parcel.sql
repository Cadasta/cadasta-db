
/********************************************************

    cd_update_parcel

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
                parcel_id, origin_id, version, description,
                spatial_source, user_id, area, length, geom, land_use, gov_pin)
	            VALUES (p_id, p_id, cd_new_version, COALESCE(cd_description,(SELECT description FROM parcel_history where parcel_id = p_id GROUP BY description, version ORDER BY version DESC LIMIT 1)),
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