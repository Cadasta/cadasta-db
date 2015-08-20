-- SELECT * FROM cd_create_parcel ('survey_sketch',5,222.45,'point',null,null,'62.640826','-114.233223',null,null,'just got this yesterday');
-- SELECT * FROM cd_create_parcel('survey_sketch',5,22.45,null,null,null,'new joint');
-- select * from parcel
-- select * from parcel_history

CREATE OR REPLACE FUNCTION cd_create_parcel(spatial_source character varying,
                                            ckan_user_id integer,
                                            area numeric,
                                            geom geometry,
                                            land_use land_use,
                                            gov_pin character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  ph_id integer;
  cd_geometry geometry;
  cd_parcel_timestamp timestamp;
  cd_user_id int;
  cd_area numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_gov_pin character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- spatial source and ckan id required
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

        -- get time
        SELECT INTO cd_parcel_timestamp * FROM localtimestamp;

        SELECT INTO cd_current_date * FROM current_date;

        cd_area := area::numeric;
        cd_gov_pin := gov_pin;
        cd_land_use := land_use;
        cd_spatial_source = spatial_source;
        cd_history_description = history_description;
        cd_user_id = ckan_user_id::int;
        cd_geometry = geom;

        SELECT INTO cd_spatial_source_id id FROM spatial_source WHERE type = cd_spatial_source;

	    IF cd_spatial_source_id IS NOT NULL THEN
				INSERT INTO parcel (spatial_source,user_id,geom,area,land_use,gov_pin,created_by) VALUES
				(cd_spatial_source_id,cd_user_id,cd_geometry,cd_area,cd_land_use,cd_gov_pin,cd_user_id) RETURNING id INTO p_id;
				RAISE NOTICE 'Successfully created parcel, id: %', p_id;

				INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified,created_by) VALUES
				(p_id,p_id,cd_history_description,cd_current_date,cd_user_id) RETURNING id INTO ph_id;
				RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;
		ELSE
		    RAISE NOTICE 'Invalid spatial source';
		END IF;

	    IF p_id IS NOT NULL THEN
		RETURN p_id;
	    ELSE
		RAISE NOTICE 'Unable to create Parcel';
		RETURN NULL;
	    END IF;

	ELSE
	    RAISE NOTICE 'The following parameters are required: spatial_source, ckan_user_id, geom_type';
	    RAISE NOTICE 'spatial_source:%  ckan_user_id:% ', $1, $2;
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;