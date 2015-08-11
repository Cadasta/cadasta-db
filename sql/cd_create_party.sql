-- Create new party

DROP FUNCTION IF EXISTS cd_create_party(first_name character varying, last_name character varying);

CREATE OR REPLACE FUNCTION cd_create_party(first_name character varying, last_name character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
BEGIN

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN
	-- Save the original organization ID variable
    INSERT INTO party (first_name, last_name) VALUES (first_name,last_name) RETURNING id INTO p_id person_id;

	RETURN p_id;

	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

