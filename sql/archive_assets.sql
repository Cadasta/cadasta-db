-- Archive parcel

DROP FUNCTION IF EXISTS cd_archive_parcel(parcel_id integer);

CREATE OR REPLACE FUNCTION cd_archive_parcel(parcel_id integer)
  RETURNS BOOLEAN AS $$
  DECLARE
  p_id integer;
BEGIN

    -- Must have a value in the parameter
    IF $1 IS NOT NULL THEN

        -- Make sure parcel id exists
        SELECT INTO p_id id FROM parcel where id = $1;

        IF p_id IS NOT NULL THEN
            RAISE NOTICE 'Found parcel id: %', p_id;
            -- Deactivate parcel id in parcel table
            UPDATE parcel SET active = false WHERE id = p_id;


            RETURN TRUE;
        ELSE
            RAISE NOTICE 'Cannot find parcel id: %', $1;
            RETURN FALSE;
        END IF;

    ELSE
        RAISE NOTICE 'parcel_id parameter NULL';
        RETURN FALSE;
	END IF;

END;
  $$ LANGUAGE plpgsql VOLATILE;

