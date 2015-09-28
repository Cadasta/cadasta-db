-- Create new organization
/********************************************************

    cd_create_organization

    select * from organization;

    SELECT * FROM cd_create_organization('Cadasta','Cadasta Org',null);
    SELECT * FROM cd_create_organization('Cadasta',null,null);

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_organization(ckan_org_id character varying, title character varying, description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  o_id integer;
  cd_ckan_org_id character varying;
  cd_description character varying;
  cd_title character varying;
BEGIN

    cd_ckan_org_id = ckan_org_id;
    cd_description = description;
    cd_title = title;

    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

	    -- Save the original organization ID variable
        INSERT INTO organization (title, description, ckan_id) VALUES (cd_title,cd_description,cd_ckan_org_id) RETURNING id INTO o_id;

	    RETURN o_id;
    ELSE
        RAISE NOTICE 'Missing ckan_org_id OR title';
        RETURN o_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


-- Create new project

/********************************************************

    cd_create_project

    select * from project;
    select * from organization;

    SELECT * FROM cd_create_project(1,'Medellin','Medellin Pilot');
    SELECT * FROM cd_create_project(1,'Ghana','Ghana Pilot');

    SELECT * FROM cd_create_project(2,'Ghana',null);
    SELECT * FROM cd_create_project(4,'Medellin','Medellin Pilot');

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_project(org_id integer, ckan_project_id character varying, title character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  o_id integer;
  cd_ckan_project_id character varying;
  cd_title character varying;
BEGIN

    cd_ckan_project_id = ckan_project_id;
    cd_title = title;
    cd_ckan_project_id = regexp_replace(ckan_project_id, U&'\2028', '', 'g');

    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $3 IS NOT NULL THEN

        -- Grab org id from org table
        SELECT INTO o_id id FROM organization WHERE id = $1;

        -- Validate organization id
        IF o_id IS NOT NULL AND cd_validate_organization($1) THEN

	        -- Create project and store project id
            INSERT INTO project (organization_id, ckan_id, title) VALUES (o_id,cd_ckan_project_id,cd_title) RETURNING id INTO p_id;

            RETURN p_id;
        ELSE
            RAISE NOTICE 'Invalid organization id %', $1;
            RETURN p_id;
        END IF;

    ELSE
        RAISE NOTICE 'All parameters required';
        RETURN p_id;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

