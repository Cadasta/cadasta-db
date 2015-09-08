-- Create new party

CREATE OR REPLACE FUNCTION cd_create_party(project_id int, first_name character varying, last_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  cd_project_id int;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        SELECT INTO cd_project_id id FROM project where id = $1;

        INSERT INTO party (project_id, first_name, last_name) VALUES (cd_project_id,first_name,last_name) RETURNING id INTO p_id;

	    RETURN p_id;
    ELSE
        RETURN p_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

