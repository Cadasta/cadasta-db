/********************************************************

    cd_create_parcel

    INSERT INTO organization (title) VALUES ('HFH');
    INSERT INTO project (organization_id, title) VALUES ((SELECT id from organization where title = 'HFH'), 'Bolivia');

    select * from parcel
    select * from project

    SELECT ST_LENGTH(ST_TRANSFORM((select geom from parcel where id =20),3857))
    SELECT ST_GeometryType((select geom from parcel where id =20))
    select * from parcel

-- SELECT * FROM cd_create_parcel('survey_sketch','11', 1 ,(select geom from parcel where id = 7),null,null,'new description');
-- select * from parcel
-- select * from parcel_history

*********************************************************/
CREATE OR REPLACE FUNCTION cd_create_parcel(spatial_source character varying,
                                            ckan_user_id integer,
                                            project_id integer,
                                            geom geometry,
                                            land_use land_use,
                                            gov_pin character varying,
                                            history_description character varying)
  RETURNS INTEGER AS $$
  DECLARE
  p_id integer;
  ph_id integer;
  cd_project_id integer;
  cd_geometry geometry;
  cd_geom_type character varying;
  cd_user_id int;
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_gov_pin character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- spatial source and ckan id required
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

        SELECT INTO cd_project_id id FROM project where id = $3;

        IF cd_project_id IS NOT NULL THEN
            SELECT INTO cd_current_date * FROM current_date;

            cd_gov_pin := gov_pin;
            cd_land_use := land_use;
            cd_spatial_source = spatial_source;
            cd_history_description = history_description;
            cd_user_id = ckan_user_id::int;
            cd_geometry = geom;

            SELECT INTO cd_spatial_source_id id FROM spatial_source WHERE type = cd_spatial_source;

            SELECT INTO cd_geom_type * FROM ST_GeometryType(cd_geometry); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

             IF cd_geom_type iS NOT NULL THEN
                  RAISE NOTICE 'cd_geom_type: %', cd_geom_type;
                 CASE (cd_geom_type)
                    WHEN 'ST_Polygon' THEN
                        cd_area = ST_AREA(ST_TRANSFORM(cd_geometry,3857)); -- get area in meters
                    WHEN 'ST_LineString' THEN
                        cd_length = ST_LENGTH(ST_TRANSFORM(cd_geometry,3857)); -- get length in meters
                        RAISE NOTICE 'length: %', cd_length;
                    ELSE
                        RAISE NOTICE 'Parcel is a point';
                 END CASE;
             END IF;

	        IF cd_spatial_source_id IS NOT NULL THEN
				    INSERT INTO parcel (spatial_source,project_id, user_id,geom,area,length,land_use,gov_pin,created_by) VALUES
				    (cd_spatial_source_id,cd_project_id,cd_user_id,cd_geometry,cd_area,cd_length,cd_land_use,cd_gov_pin,cd_user_id) RETURNING id INTO p_id;
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
	        RAISE NOTICE 'Invalid project id';
	        RETURN NULL;
	    END IF;

	ELSE
	    RAISE NOTICE 'The following parameters are required: spatial_source, ckan_user_id, geom_type';
	    RAISE NOTICE 'spatial_source:%  ckan_user_id:% ', $1, $2;
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;