/******************************************************************
 Change Script 0.0.10
 Date: 11/12/15

 1. Validate respondents function takes new status argument

 ******************************************************************/

DROP FUNCTION cd_validate_respondents(character varying);

/******************************************************************

  cd_validate_respondents

  SELECT * FROM cd_validate_respondents('21,18,19', true);

  select * from respondent;

  update respondent set validated = false;
  update parcel set validated = false;
  update relationship set validated = false;
  update party set validated = false;

  select id, validated from parcel where id IN (select parcel_id from respondent)
  select id, validated from parcel where id IN (select parcel_id from respondent where id IN(20) )

  select id, validated from relationship where id IN (select relationship_id from respondent where id IN(20) )
  select id, validated from relationship where id IN (select relationship_id from respondent)

  select id, validated from party where id IN (select party_id from respondent where id IN(20) )
  select id, validated from party where id IN (select party_id from respondent)

******************************************************************/

CREATE OR REPLACE FUNCTION cd_validate_respondents(respondent_ids character varying, status boolean)
  RETURNS INT[] AS $$
  DECLARE
  r_field_data_id int; -- respondent field data id
  r_project_id int; -- respondent project id
  r_ids int []; -- respondent ids
  parcel_ids int []; -- parcel ids
  party_ids int []; -- party ids
  relationship_ids int []; -- relationship ids
  valid_parcel_ids int [];
  valid_party_ids int [];
  valid_relationship_ids int [];
  curr_time timestamp; -- current timestamp
  filter_respondent_ids INT[];
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        -- cast parameter into array
        filter_respondent_ids = string_to_array($1, ',')::int[];

        -- get field data id
        SELECT INTO r_field_data_id DISTINCT(field_data_id) FROM respondent WHERE id = ANY(filter_respondent_ids);

        -- get project id
        SELECT INTO r_project_id DISTINCT(project_id) FROM field_data WHERE id = r_field_data_id;

        IF r_field_data_id IS NULL THEN
            RAISE EXCEPTION 'Invalid respondent ids';
        END IF;

        IF NOT(SELECT * FROM cd_validate_project(r_project_id)) THEN
            RAISE EXCEPTION 'Invalid project id';
        END IF;

        SELECT INTO curr_time current_timestamp;

        -- Make sure respondent id exists
        SELECT INTO r_ids array_agg(id) FROM respondent where id = ANY(filter_respondent_ids);

        -- Get all parcel ids associated with respondent ids
        SELECT INTO parcel_ids array_agg(parcel_id) FROM respondent where id = ANY(filter_respondent_ids);

        -- Get all relationship ids associated with respondent ids
        SELECT INTO relationship_ids array_agg(relationship_id) FROM respondent where id = ANY(filter_respondent_ids);

        -- Get all party ids associated with respondent ids
        SELECT INTO party_ids array_agg(party_id) FROM respondent where id = ANY(filter_respondent_ids);

        -- Validate all ids
        SELECT INTO valid_parcel_ids * FROM cd_validate_parcels(array_to_string(parcel_ids,','));
        SELECT INTO valid_relationship_ids * FROM cd_validate_relationships(array_to_string(relationship_ids,','));
        SELECT INTO valid_party_ids * FROM cd_validate_parties(array_to_string(party_ids,','));

        IF r_ids IS NOT NULL THEN


            UPDATE respondent SET validated = status, time_validated = curr_time, time_updated = curr_time WHERE id = ANY(r_ids);

            -- Validate parcel, parties, and relationships
            UPDATE parcel SET validated = status, time_validated = curr_time, time_updated = curr_time WHERE id = ANY(valid_parcel_ids) and project_id = r_project_id;
            UPDATE relationship SET validated = status, time_validated = curr_time, time_updated = curr_time WHERE id = ANY(valid_relationship_ids) and project_id = r_project_id;
            UPDATE party SET validated = status, time_validated = curr_time, time_updated = curr_time WHERE id = ANY(valid_party_ids) and project_id = r_project_id;

            RETURN r_ids;

        ELSE
            RAISE EXCEPTION 'Cannot find parcel ids';
        END IF;

    ELSE
        RAISE EXCEPTION 'Parameter is required';
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;