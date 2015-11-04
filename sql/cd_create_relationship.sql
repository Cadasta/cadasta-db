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
