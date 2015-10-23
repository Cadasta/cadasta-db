/********************************************************

    cd_update_function

    select * from parcel WHERE id = 3
    select * from parcel_history where parcel_id = 3

    SELECT NOT(ST_Equals((SELECT geom FROM parcel_history where id = 14), (select geom from parcel_history where id = 15)))

    SELECT version from parcel_history where parcel_id = 3 order by version desc limit 1

    SELECT SUM(version + 1) FROM parcel_history where parcel_id = 3 GROUP BY VERSION ORDER BY VERSION DESC LIMIT 1;

    SELECT * FROM cd_update_parcel (3, $anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'digitized', 
    'Commercial' , '331321sad', null);

*********************************************************/
-- DROP FUNCTION cd_update_parcel(integer, character varying, character varying, land_use, character varying, character varying);

CREATE OR REPLACE FUNCTION cd_update_parcel(cd_parcel_id integer,
                                                     cd_geojson character varying,
                                                     cd_spatial_source character varying,
                                                     cd_land_use land_use,
                                                     cd_gov_pin character varying,
                                                     cd_description character varying
                                                     )
  RETURNS INTEGER AS $$
  DECLARE

  p_id integer;
  ph_id integer;
  cd_geom geometry;
  cd_new_version integer;
  cd_current_date date;
  cd_geom_type character varying;
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source_id integer; 

  cd_geom_origin geometry;
  cd_spatial_source_id_origin integer;
  cd_land_use_origin land_use;
  cd_gov_pin_origin character varying;
  cd_description_origin character varying;

BEGIN
    -- 1. update parcel record
    -- 2. create parcel hisotry record
    SELECT INTO p_id id FROM PARCEL WHERE id = $1;

    IF cd_validate_parcel(p_id) THEN

        SELECT INTO cd_spatial_source_id id FROM spatial_source where type = cd_spatial_source;
        SELECT INTO cd_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(cd_geojson),4326); -- convert to LAT LNG GEOM

        -- get original values
        SELECT INTO cd_geom_origin geom FROM parcel WHERE id = p_id;
        SELECT INTO cd_spatial_source_id_origin spatial_source FROM parcel WHERE id = p_id;
        SELECT INTO cd_land_use_origin land_use FROM parcel WHERE id = p_id;
        SELECT INTO cd_gov_pin_origin gov_pin FROM parcel where id = p_id;
        SELECT INTO cd_description_origin description FROM parcel_history where parcel_id = p_id ORDER BY version DESC LIMIT 1;

        -- Ensure at least one value is differnt from original
        IF NOT(ST_Equals(cd_geom_origin,cd_geom)) OR (cd_spatial_source_id_origin != cd_spatial_source_id) OR (cd_land_use_origin != cd_land_use) OR (cd_gov_pin_origin != cd_gov_pin) OR (cd_description_origin != cd_description) THEN

           SELECT INTO cd_geom_type * FROM ST_GeometryType(cd_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

             -- need geometry type for area, length calculation
             IF cd_geom_type iS NOT NULL THEN
                  RAISE NOTICE 'cd_geom_type: %', cd_geom_type;
                 CASE (cd_geom_type)
                    WHEN 'ST_Polygon' THEN
                        cd_area = ST_AREA(ST_TRANSFORM(cd_geom,3857)); -- get area in meters
                    WHEN 'ST_LineString' THEN
                        cd_length = ST_LENGTH(ST_TRANSFORM(cd_geom,3857)); -- get length in meters
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
        area = COALESCE(cd_area, area),
        length = COALESCE(cd_length, length),
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
            RAISE EXCEPTION 'All values match original version';
        END IF;
	
    ELSE
        RAISE EXCEPTION 'Invalid Parcel id';
    END IF;

END;
$$ LANGUAGE plpgsql VOLATILE;