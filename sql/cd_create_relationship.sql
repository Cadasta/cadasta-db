/******************************************************************

 cd_create_relationship

-- Create relationship with relationship geometry

SELECT * FROM cd_create_relationship(1,7,null,4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$,'lease',current_date,'stolen','family fortune');
SELECT * FROM cd_create_relationship(1,3,null,4,$anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$,'lease',current_date,null,null);

select * from relationship_geometry where id = 15
select * from relationship_history where relationship_id = 45
select * from relationship where id = 45

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
  cd_party_id int;
  cd_geom_id int;
  cd_tenure_type_id int;
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
        cd_geojson = geojson::text;
        cd_acquired_date = acquiredDate;
        cd_how_acquired = howAcquired;

	    -- get parcel_id
        SELECT INTO cd_parcel_id id FROM parcel where id = $2 AND project_id = p_id;
        -- get party_id
        SELECT INTO cd_party_id id FROM party where id = $4 AND project_id = p_id;
        -- get tenure type id
        SELECT INTO cd_tenure_type_id id FROM tenure_type where type = $6;

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
            INSERT INTO relationship (project_id,created_by,parcel_id,party_id,tenure_type,geom_id,acquired_date,how_acquired)
            VALUES (p_id,ckan_user_id,cd_parcel_id,cd_party_id, cd_tenure_type_id, cd_geom_id, cd_acquired_date,cd_how_acquired) RETURNING id INTO r_id;

            IF r_id IS NOT NULL THEN

                -- create relationship history
                INSERT INTO relationship_history (relationship_id,origin_id,active,description,date_modified, created_by, parcel_id, party_id, geom_id, tenure_type, acquired_date, how_acquired)
                VALUES (r_id,r_id,true,cd_history_description, cd_current_date, cd_ckan_user_id, (SELECT parcel_id FROM relationship where id = r_id), (SELECT party_id FROM relationship where id = r_id),
                (SELECT geom_id FROM relationship where id = r_id), (SELECT tenure_type FROM relationship where id = r_id), (SELECT acquired_date FROM relationship where id = r_id), (SELECT how_acquired FROM relationship where id = r_id)) RETURNING id INTO rh_id;

                IF geojson IS NOT NULL THEN
                    -- create relationship geometry
                    SELECT INTO cd_geom_id * FROM cd_create_relationship_geometry(p_id, r_id, cd_geojson);
                    IF cd_geom_id IS NOT NULL AND rh_id IS NOT NULL THEN
                        UPDATE relationship_history SET geom_id = cd_geom_id WHERE id = rh_id;
                        RETURN r_id;
                    ELSE
                        RAISE EXCEPTION 'Unable to create relationship geometry';
                    END IF;
                ELSE
                    RETURN r_id;
                END IF;

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
