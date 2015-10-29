/******************************************************************
    cd_create_party

    Create new party

    -- Create new party Ian O'Guin for project 1
    SELECT * FROM cd_create_party(1, 'individual', 'Ian', 'O''Guin', null);
    -- Create new party group Wal Mart for project 1
    SELECT * FROM cd_create_party(1, 'group', null, null, 'Wal-Mart');

******************************************************************/


CREATE OR REPLACE FUNCTION cd_create_party(project_id int, cd_party_type party_type, first_name character varying, last_name character varying, cd_group_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
  cd_party_type_lower character varying;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND (($3 IS NOT NULL) OR ($5 IS NOT NULL)) THEN

        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, type, first_name, last_name, group_name) VALUES (cd_project_id, cd_party_type, first_name,last_name, cd_group_name) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RAISE EXCEPTION 'project_id, party_type , first_name OR group_name required';
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;
