-- Create new survey

DROP FUNCTION IF EXISTS cd_create_survey(id_string character varying);

CREATE OR REPLACE FUNCTION cd_create_survey(id_string character varying)
  RETURNS INTEGER AS $$
  DECLARE
  s_id integer;
  survey_id_string character varying;
BEGIN

    survey_id_string = id_string;

    IF survey_id_string IS NOT NULL THEN
	-- Create survey and return survey id
    INSERT INTO survey (id_string) VALUES (survey_id_string) RETURNING id INTO s_id;

	RETURN s_id;

	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

