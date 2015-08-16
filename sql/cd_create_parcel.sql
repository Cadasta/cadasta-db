-- SELECT * FROM cd_create_parcel ('survey_sketch',5,222.45,'point',null,null,'62.640826','-114.233223',null,null,'just got this yesterday');
-- select * from parcel
-- select * from parcel_history

DROP FUNCTION IF EXISTS cd_create_parcel(spatial_source character varying,ckan_user_id integer,area numeric,geom_type character varying,line geometry,
polygon geometry,lat numeric,lng numeric,land_use land_use,gov_pin character varying);

CREATE OR REPLACE FUNCTION cd_create_parcel(spatial_source character varying,
                                            ckan_user_id integer,
                                            area numeric,
                                            geom_type character varying,
                                            geom geometry,
                                            lat numeric,
                                            lng numeric,
                                            land_use land_use,
                                            gov_pin character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  ph_id integer;
  geometry geometry;

  cd_geometry_type character varying;
  cd_parcel_timestamp timestamp;
  cd_user_id int;
  cd_area numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_gov_pin character varying;
  cd_lat numeric;
  cd_lng numeric;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- geometry is not required at first
    IF $1 IS NOT NULL AND $2 IS NOT NULL AND $4 IS NOT NULL AND ($5 IS NOT NULL OR ($6 IS NOT NULL AND $7 IS NOT NULL)) THEN

        -- get time
        SELECT INTO cd_parcel_timestamp * FROM localtimestamp;

        -- get geom
        SELECT INTO cd_geometry_type * FROM initcap(geom_type);

        SELECT INTO cd_current_date * FROM current_date;

        cd_lat := lat::numeric;
        cd_lng := lng::numeric;
        cd_area := area::numeric;
        cd_gov_pin := gov_pin;
        cd_land_use := land_use;
        cd_spatial_source = spatial_source;
        cd_history_description = history_description;
        cd_user_id = ckan_user_id::int;

        SELECT INTO cd_spatial_source_id id FROM spatial_source WHERE type = cd_spatial_source;

	    IF cd_spatial_source IS NOT NULL THEN

	    IF cd_geometry_type IS NOT NULL THEN
	        -- get geom type
	        IF cd_geometry_type ='Polygon' THEN
			cd_geometry_type = '';
		ELSIF cd_geometry_type = 'Point' AND cd_lat IS NOT NULL AND cd_lng IS NOT NULL THEN

			SELECT INTO geometry * FROM ST_SetSRID(ST_MakePoint(cd_lat, cd_lng),4326);

			RAISE NOTICE 'GEOM: %', geometry;

			IF geometry IS NOT NULL THEN
				INSERT INTO parcel (spatial_source,user_id,geom,area,land_use,gov_pin,created_by) VALUES
				(cd_spatial_source_id,cd_user_id, geometry,cd_area,cd_land_use,cd_gov_pin,cd_user_id) RETURNING id INTO p_id;
				RAISE NOTICE 'Successfully created parcel, id: %', p_id;

				INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified,created_by) VALUES
				(p_id,p_id,cd_history_description,cd_current_date,cd_user_id) RETURNING id INTO ph_id;
				RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;

			ELSE
				RAISE NOTICE 'Geometry is required';
				RETURN NULL;
			END IF;
		END IF;

		END IF;

	    ELSE
		RAISE NOTICE 'Geometry Type is required. (Point, Polygon, or Line)';
		RETURN NULL;
	    END IF;

	    IF p_id IS NOT NULL THEN
		RETURN p_id;
	    ELSE
		RAISE NOTICE 'Unable to create Parcel';
		RETURN NULL;
	    END IF;

	ELSE
	    RAISE NOTICE 'The following parameters are required: spatial_source, ckan_user_id, geom_type';
	    RAISE NOTICE '1:%  2:%  3:%  4:%  5%:  :6%  :7%   8:%  9:%  10:% ', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10;
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;