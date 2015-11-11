/******************************************************************
    cd_create_party

    -- Create new party Ian O'Guin for project 1
    SELECT * FROM cd_create_party(1, 'individual', 'Ian', null, 'Male', '4-25-1990', 'my name is Ian', '14u1oakldaCCCC');

    -- Create new party group Wal Mart for project 1
    SELECT * FROM cd_create_party(1, 'group', null, 'Wal-Mart', null, null, null, null);

    -- FAIL: Add a group with a full name
    SELECT * FROM cd_create_party(1, 'group', 'Daniel Baah', 'Wal-Mart', null, null, null, null);


******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_party(project_id int,
                                            cd_party_type party_type,
                                            full_name character varying,
                                            cd_group_name character varying,
                                            cd_gender character varying,
                                            cd_dob date,
                                            cd_description character varying,
                                            cd_national_id character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
  cd_party_type_lower character varying;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND (($3 IS NOT NULL) OR ($4 IS NOT NULL)) THEN

        IF ($3 IS NOT NULL AND $4 IS NOT NULL) THEN
            RAISE EXCEPTION 'Cannot have an individual and group name';
        END IF;


        IF ($3 IS NOT NULL AND $2 = 'group') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;

        IF ($4 IS NOT NULL AND $2 = 'individual') THEN
            RAISE EXCEPTION 'Invalid party type';
        END IF;
        
        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, type, full_name, group_name, gender, dob, description, national_id)
        VALUES (cd_project_id, cd_party_type, full_name, cd_group_name, cd_gender, cd_dob, cd_description, cd_national_id) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RAISE EXCEPTION 'project_id, party_type , full_name OR group_name required';
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;
