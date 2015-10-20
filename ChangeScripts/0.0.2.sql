/******************************************************************
Change Script 0.0.2
Date: 10/20/15

    1. Add description field to organization and project table
    2. Update create project function

******************************************************************/

DROP FUNCTION cd_create_project(integer, character varying, character varying, character varying);
ALTER TABLE project ADD COLUMN description character varying;

CREATE OR REPLACE FUNCTION cd_create_project(org_id integer, ckan_project_id character varying, ckan_name character varying, title character varying, description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  o_id integer;
  cd_ckan_name character varying;
  cd_ckan_project_id character varying;
  cd_title character varying;
  cd_description character varying;
BEGIN

    cd_ckan_project_id = regexp_replace($2, U&'\2028', '', 'g');
    cd_ckan_name = $3;
    cd_title = $4;
    cd_description = $5;

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        -- Grab org id from org table
        SELECT INTO o_id id FROM organization WHERE id = $1;

        -- Validate organization id
        IF o_id IS NOT NULL AND cd_validate_organization($1) THEN

	        -- Create project and store project id
            INSERT INTO project (organization_id, ckan_name, ckan_id, title, description) VALUES (o_id, cd_ckan_name, cd_ckan_project_id,cd_title, cd_description) RETURNING id INTO p_id;

            RETURN p_id;
        ELSE
            RAISE EXCEPTION 'Invalid organization';
            RETURN p_id;
        END IF;

    ELSE
        RAISE EXCEPTION 'All parameters required';
        RETURN p_id;
    END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;