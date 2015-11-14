
/********************************************************

    cd_update_relationship

    SELECT * FROM cd_create_relationship(1,1,null,22,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'easement',current_date,'stolen','family fortune');

    -- Update relationship 1's tenure type, how acqured, and history description
    SELECT * FROM cd_update_relationship(1,33,null,null,null,'mineral rights',null, 'taken over by government', 'informed in the mail');

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
							cd_acquired_date timestamp with time zone,
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
        INSERT INTO relationship_history (version, area, length, relationship_id, origin_id,description, parcel_id, party_id, geom, tenure_type, acquired_date, how_acquired)

        VALUES (cd_new_version, 
        (SELECT area FROM relationship where id = valid_relationship_id), 
        (SELECT length FROM relationship where id = valid_relationship_id), 
        valid_relationship_id,
        valid_relationship_id,
        COALESCE(cd_history_description,(SELECT description FROM relationship_history where relationship_id = valid_relationship_id GROUP BY description, version ORDER BY version DESC LIMIT 1)), 
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