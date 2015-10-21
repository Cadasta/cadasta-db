/******************************************************************
Change Script 0.0.3
Date: 10/21/15

    1. Remove not null constraint from user_id in parcel table
    2. Update create parcel function

******************************************************************/

ALTER TABLE parcel ALTER COLUMN user_id DROP NOT NULL;
DROP FUNCTION cd_create_parcel(character varying, integer, integer, geometry, land_use, character varying, character varying);

/********************************************************

    cd_create_parcel

    select * from parcel

    SELECT * FROM cd_create_parcel(1, 'digitized', null, 'Commercial', null, 'insert description here');
    
    SELECT * FROM cd_create_parcel(3, 'survey_sketch', $anystr${
        "type": "Polygon",
        "coordinates": [
          [
            [
              -121.73335433006287,
              44.571446955240106
            ],
            [
              -121.73388004302979,
              44.57033871490996
            ],
            [
              -121.7328178882599,
              44.56994127185396
            ],
            [
              -121.73189520835876,
              44.570804942725566
            ],
            [
              -121.73335433006287,
              44.571446955240106
            ]
          ]
        ]
      }$anystr$, 'Residential', null, 'insert description here');


      SELECT * FROM cd_create_parcel(1, 'digitized', 	$anystr${
        "type": "LineString",
        "coordinates": [
          [
            -121.73326581716537,
            44.5723908536272
          ],
          [
            -121.7331075668335,
            44.57247110339075
          ]
        ]
      }$anystr$, 'Commercial', null, 'insert description here');


-- select * from parcel
-- select * from parcel_history

*********************************************************/

-- Function: cd_create_parcel(integer, character varying, geometry, land_use, character varying, character varying)

-- DROP FUNCTION cd_create_parcel(integer, character varying, characer varying, land_use, character varying, character varying);

CREATE OR REPLACE FUNCTION cd_create_parcel(project_id integer,
                                            spatial_source character varying,
                                            geojson character varying,
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
  cd_area numeric;
  cd_length numeric;
  cd_spatial_source character varying;
  cd_spatial_source_id int;
  cd_land_use land_use;
  cd_geojson character varying;
  cd_gov_pin character varying;
  cd_history_description character varying;
  cd_current_date date;

BEGIN

    -- spatial source and project id required
    IF $1 IS NOT NULL AND $2 IS NOT NULL THEN

        SELECT INTO cd_project_id id FROM project where id = $1;

        IF cd_project_id IS NOT NULL THEN
            SELECT INTO cd_current_date * FROM current_date;

            cd_gov_pin := gov_pin;
            cd_land_use := land_use;
            cd_spatial_source = spatial_source;
            cd_history_description = history_description;
            cd_geojson = geojson;

            SELECT INTO cd_geometry * FROM ST_SetSRID(ST_GeomFromGeoJSON(cd_geojson),4326); -- convert to LAT LNG GEOM

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
				    INSERT INTO parcel (spatial_source,project_id,geom,area,length,land_use,gov_pin) VALUES
				    (cd_spatial_source_id,cd_project_id,cd_geometry,cd_area,cd_length,cd_land_use,cd_gov_pin) RETURNING id INTO p_id;
				    RAISE NOTICE 'Successfully created parcel, id: %', p_id;

				    INSERT INTO parcel_history (parcel_id,origin_id,description,date_modified) VALUES
				    (p_id,p_id,cd_history_description,cd_current_date) RETURNING id INTO ph_id;
				    RAISE NOTICE 'Successfully created parcel history, id: %', ph_id;
		    ELSE
		        RAISE EXCEPTION 'Invalid spatial source';
		    END IF;

	        IF p_id IS NOT NULL THEN
		        RETURN p_id;
	        ELSE
		        RAISE EXCEPTION 'Unable to create Parcel';
	        END IF;
	    ELSE
	        RAISE EXCEPTION 'Invalid project id';
	    END IF;

	ELSE
	    RAISE EXCEPTION 'The following parameters are required: spatial_source, project_id';
	    RETURN NULL;
	END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;