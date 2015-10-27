  /********************************************************

    cd_create_organization

    select * from organization;

    SELECT * FROM cd_create_organization('grow','123fadsaa', 'GROW Project', 'Created in response to GROW');`

*********************************************************/

CREATE OR REPLACE FUNCTION cd_create_organization(ckan_name character varying, ckan_org_id character varying , title character varying, description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer;
  cd_ckan_org_name character varying;
  cd_description character varying;
  cd_title character varying;
  cd_ckan_id character varying;
BEGIN

    cd_ckan_org_name = $1;
    cd_ckan_id = $2;
    cd_title = $3;
    cd_description = $4;

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

	    -- Save the original organization ID variable
        INSERT INTO organization (title, description, ckan_name, ckan_id) VALUES (cd_title,cd_description,cd_ckan_org_name,cd_ckan_id) RETURNING id INTO o_id;

	    RETURN o_id;
    ELSE
        RAISE EXCEPTION 'Missing ckan_name or ckan_org_id';
        RETURN o_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

  /********************************************************

    cd_create_project

    select * from project;
    select * from organization;

    SELECT * FROM cd_create_project(1,'meddyypilot', 'Meddy', 'Medeyy Pilor', 'descripton', '1qewdasaseq1eqeweqasda11ewq');

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_project(org_id integer, ckan_project_id character varying, ckan_name character varying, title character varying, description character varying, api_key character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  o_id integer;
  cd_ckan_name character varying;
  cd_ckan_project_id character varying;
  cd_title character varying;
  cd_description character varying;
  cd_api_key character varying;
BEGIN

    cd_ckan_project_id = regexp_replace($2, U&'\2028', '', 'g');
    cd_ckan_name = $3;
    cd_title = $4;
    cd_description = $5;
    cd_api_key = $6;

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        -- Grab org id from org table
        SELECT INTO o_id id FROM organization WHERE id = $1;

        -- Validate organization id
        IF o_id IS NOT NULL AND cd_validate_organization($1) THEN

	        -- Create project and store project id
            INSERT INTO project (organization_id, ckan_name, ckan_id, title, description, ona_api_key) VALUES (o_id, cd_ckan_name, cd_ckan_project_id,cd_title, cd_description, cd_api_key) RETURNING id INTO p_id;

            RETURN p_id;
        ELSE
            RAISE EXCEPTION 'Invalid organization';
            RETURN p_id;
        END IF;

    ELSE
        RAISE EXCEPTION 'Parameters org_id, ckan_project_id, and ckan_name required';
        RETURN p_id;
    END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;