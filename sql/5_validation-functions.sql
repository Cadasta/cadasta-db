/******************************************************************
  cd_delete_parcel

******************************************************************/

CREATE OR REPLACE FUNCTION cd_delete_parcel(parcel_id integer)
  RETURNS BOOLEAN AS $$
  DECLARE
  p_id integer; -- parcel id
  r_ids integer []; -- relationship ids
  curr_time timestamp; -- current timestamp
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- Make sure parcel id exists
        SELECT INTO p_id id FROM parcel where id = $1;

        IF p_id IS NOT NULL THEN
            RAISE NOTICE 'Found parcel id: %', p_id;
            -- Deactivate parcel id in parcel table
            UPDATE parcel SET active = false, sys_delete = true, time_updated = curr_time WHERE id = p_id;

            -- Collect all relationships that are associated with parcel
            SELECT INTO r_ids array_agg(id) FROM relationship r where r.parcel_id = p_id;

            IF r_ids IS NOT NULL THEN
                RAISE NOTICE 'Associated relationship ids: %', r_ids;
                -- Deactivate & System delete all relationships
                UPDATE relationship SET active = false, sys_delete = true, time_updated = curr_time WHERE id = ANY(r_ids);
                RETURN TRUE;
            ELSE
                -- Parcel is not associated with Relationship
                RETURN TRUE;
            END IF;
        ELSE
            RAISE NOTICE 'Cannot find parcel id: %', $1;
            RETURN FALSE;
        END IF;

    ELSE
        RAISE NOTICE 'Parcel id is NULL';
        RETURN FALSE;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_delete_relationship

******************************************************************/

CREATE OR REPLACE FUNCTION cd_delete_relationship(relationship_id integer)
  RETURNS BOOLEAN AS $$
  DECLARE
  r_id integer; -- relationship id
  curr_time timestamp; -- current timestamp
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- Make sure relationship id exists
        SELECT INTO r_id id FROM relationship where id = $1;

        IF r_id IS NOT NULL THEN
            RAISE NOTICE 'Found relationship id: %', r_id;
            -- Deactivate relationship id in relationship table
            UPDATE relationship SET active = false, sys_delete = true, time_updated = curr_time WHERE id = r_id;
            RETURN TRUE;
        ELSE
            RAISE NOTICE 'Cannot find relationship id: %', $1;
            RETURN FALSE;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship id is NULL';
        RETURN FALSE;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_delete_relationships

******************************************************************/

CREATE OR REPLACE FUNCTION cd_delete_relationships(relationships_ids character varying)
  RETURNS INT[] AS $$
  DECLARE
  r_ids INT []; -- relationship ids
  curr_time timestamp; -- current timestamp
  filter_relationship_ids INT[];
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- cast parameter into array
        filter_relationship_ids = string_to_array($1, ',')::int[];

        -- Make sure parcel id exists
        SELECT INTO r_ids array_agg(id) FROM relationship where id = ANY(filter_relationship_ids);
        RAISE NOTICE 'List of relationships_ids: %', r_ids;

        IF r_ids IS NOT NULL THEN
            RAISE NOTICE 'Found relationship id: %', r_ids;
            -- Deactivate parcel & system delete parcel id in parcel table
            UPDATE relationship SET active = false, sys_delete = true, time_updated = curr_time WHERE id = ANY(r_ids);

            RETURN r_ids;
        ELSE
            RAISE NOTICE 'Cannot find relationship id: %', $1;
            RETURN r_ids;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship ids is NULL';
        RETURN r_ids;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_delete_parcels

******************************************************************/

CREATE OR REPLACE FUNCTION cd_delete_parcels(parcel_ids character varying)
  RETURNS INT[] AS $$
  DECLARE
  p_ids INT[]; -- parcel ids
  r_ids INT []; -- relationship ids
  curr_time timestamp; -- current timestamp
  filter_parcel_ids INT[];

BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- cast parameter into array
        filter_parcel_ids = string_to_array($1, ',')::int[];

        -- Make sure parcel id exists
        SELECT INTO p_ids array_agg(id) FROM parcel where id = ANY(filter_parcel_ids);
        RAISE NOTICE 'List of parcel_ids: %', p_ids;

        IF p_ids IS NOT NULL THEN
            RAISE NOTICE 'Found parcel id: %', p_ids;
            -- Deactivate parcel & system delete parcel id in parcel table
            UPDATE parcel SET active = false, sys_delete = true, time_updated = curr_time WHERE id = ANY(p_ids);

            -- Collect all relationships that are associated with parcel
            SELECT INTO r_ids array_agg(id) FROM relationship r where r.parcel_id = ANY(p_ids);

            IF r_ids IS NOT NULL THEN
                RAISE NOTICE 'Associated relationship ids: %', r_ids;
                -- Deactivate & system delete all relationships
                UPDATE relationship SET active = false, sys_delete = true, time_updated = curr_time WHERE id = ANY(r_ids);

                RETURN p_ids;
            END IF;
        ELSE
            RAISE NOTICE 'Cannot find parcel id: %', $1;
            RETURN p_ids;
        END IF;

    ELSE
        RAISE NOTICE 'Parcel ids is NULL';
        RETURN p_ids;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_archive_parcels

******************************************************************/

CREATE OR REPLACE FUNCTION cd_archive_parcels(parcel_ids character varying)
  RETURNS INT[] AS $$
  DECLARE
  p_ids integer []; -- project id
  r_ids integer []; -- relationship ids
  valid_ids int [];
  curr_time timestamp; -- current timestamp
  filter_parcel_ids INT[];
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- cast parameter into array
        filter_parcel_ids = string_to_array($1, ',')::int[];

        -- Make sure parcel id exists
        SELECT INTO p_ids array_agg(id) FROM parcel where id = ANY(filter_parcel_ids);

        -- Validate parcel ids
        SELECT INTO valid_ids * FROM cd_validate_parcels(array_to_string(p_ids,','));

        IF valid_ids IS NOT NULL THEN
            RAISE NOTICE 'Found parcel idS: %', valid_ids;
            -- Deactivate parcel id in parcel table
            UPDATE parcel SET active = false, time_updated = curr_time WHERE id = ANY(valid_ids);

            -- Collect all relationships that are associated with parcel
            SELECT INTO r_ids array_agg(id) FROM relationship r where r.parcel_id = ANY(valid_ids);

            IF r_ids IS NOT NULL THEN
                RAISE NOTICE 'Associated relationship ids: %', r_ids;
                -- Deactivate all relationships
                UPDATE relationship SET active = false, time_updated = curr_time WHERE id = ANY(r_ids);

                RETURN valid_ids;
            ELSE
                RETURN valid_ids;
            END IF;
        ELSE
            RAISE NOTICE 'Cannot find parcel ids: %', $1;
            RETURN valid_ids;
        END IF;

    ELSE
        RAISE NOTICE 'Parameter is required';
        RETURN valid_ids;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_archive_relationships

******************************************************************/

CREATE OR REPLACE FUNCTION cd_archive_relationships(relationship_ids character varying)
  RETURNS INT[] AS $$
  DECLARE
  r_ids integer []; -- relationship ids
  valid_ids int [];
  curr_time timestamp; -- current timestamp
  filter_relationship_ids INT[];
BEGIN

    -- Validate parcel
    IF $1 IS NOT NULL THEN

        SELECT INTO curr_time current_timestamp;

        -- cast parameter into array
        filter_relationship_ids = string_to_array($1, ',')::int[];

        -- Make sure relationship ids exists
        SELECT INTO r_ids array_agg(id) FROM relationship where id = ANY(filter_relationship_ids);

        -- Validate relationship ids
        SELECT INTO valid_ids * FROM cd_validate_relationships(array_to_string(r_ids,','));

        IF valid_ids IS NOT NULL THEN
            RAISE NOTICE 'Valid relationship ids: %', valid_ids;
            -- Deactivate all relationships
            UPDATE relationship SET active = false, time_updated = curr_time WHERE id = ANY(r_ids);
            RETURN valid_ids;
        ELSE
            RAISE NOTICE 'Cannot find relationship ids: %', $1;
            RETURN valid_ids;
        END IF;

    ELSE
        RAISE NOTICE 'Parameter is required';
        RETURN valid_ids;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;


/******************************************************************
  cd_archive_parcel

******************************************************************/
CREATE OR REPLACE FUNCTION cd_archive_parcel(parcel_id integer)
  RETURNS BOOLEAN AS $$
  DECLARE
  p_id integer; -- parcel id
  r_ids integer []; -- relationship ids
  curr_time timestamp; -- current timestamp
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

      -- Make sure parcel id exists
      SELECT INTO p_id id FROM relationship where id = $1;

      SELECT INTO curr_time current_timestamp;

      IF p_id IS NOT NULL THEN
          -- See if relationship id is active
          IF (SELECT * FROM cd_validate_parcel(p_id)) THEN
                RAISE NOTICE 'Found parcel id: %', p_id;
                -- Deactivate parcel id in parcel table
                UPDATE parcel SET active = false, time_updated = curr_time WHERE id = p_id;

                -- Collect all relationships that are associated with parcel
                SELECT INTO r_ids array_agg(id) FROM relationship r where r.parcel_id = p_id;

                IF r_ids IS NOT NULL THEN
                  RAISE NOTICE 'Associated relationship ids: %', r_ids;
                  -- Deactivate all relationships
                  UPDATE relationship SET active = false, time_updated = curr_time WHERE id = ANY(r_ids);
                  RETURN TRUE;
                ELSE
                  RETURN TRUE;
                END IF;
          ELSE
              RAISE NOTICE 'Parcel already inactive';
              RETURN FALSE;
          END IF;
        ELSE
            RAISE NOTICE 'Cannot find parcel id: %', $1;
            RETURN FALSE;
        END IF;
    ELSE
        RAISE NOTICE 'Missing parcel id in parameter';
        RETURN FALSE;
    END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_archive_relationship

******************************************************************/

CREATE OR REPLACE FUNCTION cd_archive_relationship(relationship_id integer)
  RETURNS BOOLEAN AS $$
  DECLARE
  r_id integer; -- relationship id
  curr_time timestamp; -- current timestamp
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

	    -- Make sure relationship id exists
	    SELECT INTO r_id id FROM relationship where id = $1;

	    SELECT INTO curr_time current_timestamp;

	    IF r_id IS NOT NULL THEN
	        -- See if relationship id is active
	        IF (SELECT * FROM cd_validate_relationship(r_id)) THEN
                RAISE NOTICE 'Found relationship id: %', r_id;
                -- Deactivate parcel id in parcel table
                UPDATE relationship SET active = false, time_updated = curr_time WHERE id = r_id;
	            RETURN TRUE;
	        ELSE
	            RAISE NOTICE 'Realtion already inactive';
	            RETURN FALSE;
	        END IF;
        ELSE
            RAISE NOTICE 'Cannot find relationship id: %', $1;
            RETURN FALSE;
        END IF;
    ELSE
        RAISE NOTICE 'Missing relationship id in parameter';
        RETURN FALSE;
    END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

/******************************************************************
  cd_validate_parcel

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_parcel(parcel_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN

     IF $1 IS NULL THEN
       RETURN false;
     END IF;

     SELECT INTO valid_id id FROM parcel WHERE active = true AND sys_delete = false AND id = $1;

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE
      RETURN true;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE 'plpgsql';


/******************************************************************
  cd_validate_parcels

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_parcels(parcel_ids character varying)
RETURNS INT[] AS $$
DECLARE
  valid_parcel_ids INT[];
  filter_parcel_ids INT[];
BEGIN
     IF $1 IS NULL THEN
       RETURN valid_parcel_ids;
     END IF;

     filter_parcel_ids := string_to_array($1, ',')::int[];

     SELECT INTO valid_parcel_ids array_agg(DISTINCT id)::INT[] FROM
     (SELECT id FROM parcel WHERE active = true AND sys_delete = false AND id = ANY(filter_parcel_ids) ORDER BY id) AS t;

     RETURN valid_parcel_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';


/******************************************************************
  cd_validate_relationship

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_relationship(relationship_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN

     IF $1 IS NULL THEN
       RETURN false;
     END IF;

     SELECT INTO valid_id id FROM relationship WHERE active = true AND sys_delete = false AND id = $1;

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE
      RETURN true;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE 'plpgsql';

/******************************************************************
  cd_validate_relationships

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_relationships(relationship_ids character varying)
RETURNS INT[] AS $$
DECLARE
  valid_relationship_ids INT[];
  filter_relationship_ids INT[];
BEGIN
     IF $1 IS NULL THEN
       RETURN valid_relationship_ids;
     END IF;

     filter_relationship_ids := string_to_array($1, ',')::int[];

     SELECT INTO valid_relationship_ids array_agg(DISTINCT id)::INT[] FROM
     (SELECT id FROM relationship WHERE active = true AND sys_delete = false AND id = ANY(filter_relationship_ids) ORDER BY id) AS t;

     RETURN valid_relationship_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';


/******************************************************************
  cd_validate_projects

  SELECT * FROM cd_validate_projects('1,2,3');

  SELECT * FROM project

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_projects(project_ids character varying)
RETURNS INT[] AS $$
DECLARE
  valid_project_ids INT[];
  filter_project_ids INT[];
BEGIN
     IF $1 IS NULL THEN
       RETURN valid_project_ids;
     END IF;

     filter_project_ids := string_to_array($1, ',')::int[];

     SELECT INTO valid_project_ids array_agg(DISTINCT id)::INT[] FROM
     (SELECT id FROM project WHERE active = true AND sys_delete = false AND id = ANY(filter_project_ids) ORDER BY id) AS t;

     RETURN valid_project_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

/******************************************************************
  cd_validate_project

  SELECT * FROM PROJECT;

  SELECT * FROM cd_validate_project(1);
  SELECT * FROM cd_validate_project(3);

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_project(project_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN

     IF $1 IS NULL THEN
       RETURN false;
     END IF;

     SELECT INTO valid_id id FROM project WHERE active = true AND sys_delete = false AND id = $1;

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE
      RETURN true;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE 'plpgsql';

/******************************************************************
  cd_validate_organizations

  SELECT * FROM cd_validate_organizations('1,2,3');

  SELECT * FROM organization

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_organizations(organization_ids character varying)
RETURNS INT[] AS $$
DECLARE
  valid_organization_ids INT[];
  filter_organization_ids INT[];
BEGIN
     IF $1 IS NULL THEN
       RETURN valid_organization_ids;
     END IF;

     filter_organization_ids := string_to_array($1, ',')::int[];

     SELECT INTO valid_organization_ids array_agg(DISTINCT id)::INT[] FROM
     (SELECT id FROM organization WHERE active = true AND sys_delete = false AND id = ANY(filter_organization_ids) ORDER BY id) AS t;

     RETURN valid_organization_ids;

EXCEPTION
     WHEN others THEN RETURN NULL;
END;
$$ LANGUAGE 'plpgsql';

/******************************************************************
  cd_validate_organization

  SELECT * FROM ORGANIZATION;

  SELECT * FROM cd_validate_organization(1);
  SELECT * FROM cd_validate_organization(3);

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_organization(organization_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN

     IF $1 IS NULL THEN
       RETURN false;
     END IF;

     SELECT INTO valid_id id FROM organization WHERE active = true AND sys_delete = false AND id = $1;

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE
      RETURN true;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE 'plpgsql';


/******************************************************************
  cd_validate_party

  select * from cd_validate_party(3);

******************************************************************/
CREATE OR REPLACE FUNCTION cd_validate_party(party_id integer) RETURNS boolean AS $$
DECLARE valid_id integer;
BEGIN

     IF $1 IS NULL THEN
       RETURN false;
     END IF;

     SELECT INTO valid_id id FROM party WHERE active = true AND sys_delete = false AND id = $1;

     IF valid_id IS NULL THEN
      RETURN false;
     ELSE
      RETURN true;
     END IF;

EXCEPTION WHEN others THEN
    RETURN FALSE;
END;
$$ LANGUAGE 'plpgsql';