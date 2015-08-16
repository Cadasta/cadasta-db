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