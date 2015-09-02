/******************************************************************
 TESTING cd_create_relationship_geometry

 SELECT * FROM cd_create_relationship_geometry(2,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 SELECT * FROM cd_create_relationship_geometry(4,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 SELECT * FROM cd_create_relationship_geometry(24,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);


 select * from relationship_geometry
 select * from relationship
******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_relationship_geometry(relationship_id int, geojson text)
  RETURNS INTEGER AS $$
  DECLARE

  valid_id int;
  rg_id int; -- new relationship geometry id
  data_geojson character varying; -- geojson paramater
  data_geom geometry;

  BEGIN

    IF ($1 IS NOT NULL AND $2 IS NOT NULL) THEN

        -- validate relationshup id
        IF (cd_validate_relationship($1)) THEN

            data_geojson = geojson::text;

            -- get id from relationship table
            SELECT INTO valid_id id FROM relationship where id = $1;
            -- get geom form GEOJSON
            SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

            IF data_geom IS NOT NULL AND valid_id IS NOT NULL THEN

                -- add relationship geom column
                INSERT INTO relationship_geometry (geom) VALUES (data_geom) RETURNING id INTO rg_id;

                IF rg_id IS NOT NULL THEN
                    -- add relationship geom id in relationship table
                    UPDATE relationship SET geom_id = rg_id, time_updated = current_timestamp WHERE id = valid_id;
                    RETURN rg_id;
                END IF;

            ELSE
                RAISE NOTICE 'Invalid geometry: %', geom;
                RETURN NULL;
            END IF;

        ELSE
            RAISE NOTICE 'Invalid relationship id: %', relationship_id;
            RETURN NULL;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship id and Geometry required';
        RETURN NULL;
    END IF;

  END;

$$ LANGUAGE plpgsql VOLATILE;