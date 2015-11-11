
/********************************************************

    cd_update_party
    
    -- Update party 1 - Change to group, set group_name to Walmart
    SELECT * FROM cd_update_party(1,21,'group',null,'Walmart',null,null,'group description','xxx661222x');

    -- Update party 2 - Change to individual, set name to Sam Hernandez
    SELECT * FROM cd_update_party(1,21,'individual','Sam',null,'free text gender','1990-04-25','individual description','xxx661222x');

*********************************************************/

CREATE OR REPLACE FUNCTION cd_update_party( cd_project_id int,
                                            cd_party_id int,
                                            cd_party_type party_type,
                                            cd_full_name character varying,
                                            cd_group_name character varying,
                                            cd_gender character varying,
                                            cd_dob date,
                                            cd_description character varying,
                                            cd_national_id character varying)
  RETURNS INTEGER AS $$
  DECLARE
  valid_party_id int;
BEGIN

    IF NOT(SELECT * FROM cd_validate_project(cd_project_id)) THEN
        RAISE EXCEPTION 'Invalid project id: %', cd_project_id;
    END IF;

    SELECT INTO valid_party_id id FROM party WHERE id = cd_party_id AND project_id = cd_project_id;

    IF NOT(SELECT * FROM cd_validate_party(valid_party_id)) THEN
        RAISE EXCEPTION 'Invalid party id';
    END IF;

    IF $3 = 'individual' AND cd_full_name IS NULL THEN
	RAISE EXCEPTION 'Party type individual must have full name';
    END IF;

    IF ($4 IS NOT NULL AND $3 = 'group') OR  ($3 = 'group' AND cd_group_name IS NULL) THEN
	RAISE EXCEPTION 'Party type group must have group name and no full name';
    END IF;

    -- Ensure one attribute is updated
    IF $3 IS NOT NULL OR $4 IS NOT NULL OR $5 IS NOT NULL OR $6 IS NOT NULL OR $7 IS NOT NULL OR $8 IS NOT NULL OR $9 IS NOT NULL THEN
	
        UPDATE party
        SET
        type = cd_party_type,
        full_name = cd_full_name,
        group_name = cd_group_name,
        gender = cd_gender,
        dob = cd_dob,
        description = cd_description,
        national_id = cd_national_id
        WHERE id = valid_party_id;

        RETURN valid_party_id;

    ELSE 
	RAISE EXCEPTION 'All values are null';
    END IF;


END;
  $$ LANGUAGE plpgsql VOLATILE;