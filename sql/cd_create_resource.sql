-- Create new resource
/********************************************************

    cd_create_resource

    SELECT * FROM cd_create_resource(1,'parcel',2,'http://www.cadasta.org/2/parcel',null);

    SELECT * FROM cd_create_resource(1,'party',2,'http://www.cadasta.org/2/party',null);

    SELECT * FROM cd_create_resource(1,'parcel',16,'http://www.cadasta.org/16/party',null, 'daniel-home');

    SELECT * FROM cd_create_resource(1,'relationship',4,'http://www.cadasta.org/4/relationship',null);

    select * from resource
    select * from resource_parcel
    select * from resource_party
    select * from resource_relationship

    select * from party
    select * from relationship

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_resource(project_id int, resource_type character varying, resource_type_id integer, url character varying, description character varying, filename character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer; -- organization id
  p_id integer; -- project id
  r_id integer; -- resource id
  type_id integer; -- type of resource id (parcel, party, or relationship id)
  cd_description character varying;
  cd_url character varying;
  cd_file_name character varying;
BEGIN

    cd_description = description;
    cd_url = url;
    cd_file_name = filename;

    -- project id, resource type, and url are required
    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL AND $4 IS NOT NULL THEN

        -- validate project id
        SELECT INTO p_id id FROM project WHERE id = $1;

        IF cd_validate_project(p_id) THEN

                CASE lower(resource_type)
                    -- ensure resource type is supported
                    WHEN 'parcel' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM parcel WHERE id = resource_type_id;

                        -- validate parcel id
                        IF cd_validate_parcel(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url, file_name) VALUES (p_id, cd_description, cd_url, cd_file_name) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_parcel(parcel_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid parcel id';
                            RETURN r_id;
                        END IF;
                    WHEN 'party' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM party WHERE id = resource_type_id;

                        -- validate parcel id
                        IF cd_validate_party(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url) VALUES (p_id, cd_description, cd_url) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_party(party_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid party id';
                            RETURN r_id;
                        END IF;
                    WHEN 'relationship' THEN
                        -- get resource type id from parcel table
                        SELECT INTO type_id id FROM relationship WHERE id = resource_type_id;

                        -- validate parcel id
                        IF cd_validate_relationship(type_id) THEN

                             -- Create new resource and save resource id
                            INSERT INTO resource (project_id, description, url) VALUES (p_id, cd_description, cd_url) RETURNING id INTO r_id;

                            IF r_id IS NOT NULL THEN
                                -- create resource
                                INSERT INTO resource_relationship(relationship_id, resource_id) VALUES (type_id, r_id);

                                -- update resource type
                                UPDATE resource SET type = lower(resource_type) WHERE id = r_id;

                                RETURN r_id;
                            ELSE
                                RAISE NOTICE 'Cannot create resource';
                                RETURN r_id;
                            END IF;
                        ELSE
                            RAISE NOTICE 'Invalid relationship id';
                            RETURN r_id;
                        END IF;
                ELSE
                    RAISE NOTICE 'Invalid resource type';
                    RETURN r_id;
                END CASE;

        ELSE
            RAISE NOTICE 'Invalid project id';
            RETURN r_id;
        END IF;
    ELSE
        RAISE NOTICE 'project_id, resource_type, and url are required';
        RETURN r_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;
