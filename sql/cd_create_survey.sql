-- Create new Field Data

DROP FUNCTION IF EXISTS cd_create_field_data(id_string character varying);

CREATE OR REPLACE FUNCTION cd_create_field_data(id_string character varying)
  RETURNS INTEGER AS $$
  DECLARE
  s_id integer;
  field_data_id_string character varying;
BEGIN

    field_data_id_string = id_string;

    IF field_data_id_string IS NOT NULL THEN
	-- Create survey and return survey id
    INSERT INTO field_data (id_string) VALUES (field_data_id_string) RETURNING id INTO s_id;

	RETURN s_id;

	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

