/******************************************************************

 cd_create_relationship

SELECT * FROM cd_create_relationship(3,18,11,15,null,'own','10/22/2001','Passed Down', '1st Owner');
SELECT * FROM cd_create_relationship(3,18,11,16,null,'lease','10/22/1992','Passed Down', '1st Lease');
SELECT * FROM cd_create_relationship(3,18,11,18,null,'lease','2/2/2005','Passed Down', '2nd Lease');
SELECT * FROM cd_create_relationship(3,18,11,20,null,'occupy','5/22/2009','Passed Down', '3rd Owner');
SELECT * FROM cd_create_relationship(3,18,11,22,null,'own','5/27/2009','Passed Down', '3rd Owner');
SELECT * FROM cd_create_relationship(3,18,11,24,null,'own','10/23/2009','Passed Down', '3rd Owner'); -- with date
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
