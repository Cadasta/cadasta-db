

  CREATE OR REPLACE FUNCTION truncate_db_tables() RETURNS text as $$

  DECLARE

      v_state   TEXT;
      v_msg     TEXT;
      v_detail  TEXT;
      v_hint    TEXT;
      v_context TEXT;

      BEGIN

          TRUNCATE project RESTART IDENTITY CASCADE;
          TRUNCATE organization RESTART IDENTITY CASCADE;

          	TRUNCATE option RESTART IDENTITY CASCADE;
          	TRUNCATE parcel RESTART IDENTITY CASCADE;
          	TRUNCATE relationship_geometry RESTART IDENTITY CASCADE;
          	TRUNCATE organization RESTART IDENTITY CASCADE;
          	TRUNCATE project RESTART IDENTITY CASCADE;

          	TRUNCATE parcel_history RESTART IDENTITY CASCADE;
          	TRUNCATE party RESTART IDENTITY CASCADE;
          	TRUNCATE project_extents RESTART IDENTITY CASCADE;
          	TRUNCATE project_layers RESTART IDENTITY CASCADE;
          	TRUNCATE q_group RESTART IDENTITY CASCADE;
          	TRUNCATE question RESTART IDENTITY CASCADE;
          	TRUNCATE raw_data RESTART IDENTITY CASCADE;
          	TRUNCATE raw_form RESTART IDENTITY CASCADE;
          	TRUNCATE relationship RESTART IDENTITY CASCADE;
          	TRUNCATE relationship_history RESTART IDENTITY CASCADE;
          	TRUNCATE resource RESTART IDENTITY CASCADE;
          	TRUNCATE resource_field_data RESTART IDENTITY CASCADE;
          	TRUNCATE resource_parcel RESTART IDENTITY CASCADE;
          	TRUNCATE resource_party RESTART IDENTITY CASCADE;
          	TRUNCATE respondent RESTART IDENTITY CASCADE;
          	TRUNCATE response RESTART IDENTITY CASCADE;
          	TRUNCATE responsibility RESTART IDENTITY CASCADE;
          	TRUNCATE responsibility_relationship RESTART IDENTITY CASCADE;
          	TRUNCATE restriction RESTART IDENTITY CASCADE;
          	TRUNCATE restriction_relationship RESTART IDENTITY CASCADE;
          	TRUNCATE "right" RESTART IDENTITY CASCADE;
          	TRUNCATE right_relationship  RESTART IDENTITY CASCADE;
          	TRUNCATE section RESTART IDENTITY CASCADE;
			TRUNCATE field_data RESTART IDENTITY CASCADE;

		RETURN 'Success';
      EXCEPTION WHEN others THEN
          GET STACKED DIAGNOSTICS
              v_state   = RETURNED_SQLSTATE,
              v_msg     = MESSAGE_TEXT,
              v_detail  = PG_EXCEPTION_DETAIL,
              v_hint    = PG_EXCEPTION_HINT,
              v_context = PG_EXCEPTION_CONTEXT;
          raise notice E'Got exception:
              state  : %
              message: %
              detail : %
              hint   : %
              context: %', v_state, v_msg, v_detail, v_hint, v_context;
      RETURN 'FAIL';
  END;
  $$ language PLpgSQL;