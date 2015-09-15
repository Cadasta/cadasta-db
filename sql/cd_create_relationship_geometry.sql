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

/******************************************************************
 TESTING cd_create_project_extents

 SELECT * FROM cd_create_project_extents(2,$anystr${"type": "Polygon",
    "coordinates": [
        [
            [
                -122.32929289340971,
                47.674757902221806
            ],
            [
                -122.32930362224579,
                47.67455201393344
            ],
            [
                -122.32899785041809,
                47.67455923809767
            ],
            [
                -122.32889592647551,
                47.67462064345317
            ],
            [
                -122.32885301113127,
                47.6747253935987
            ],
            [
                -122.32929289340971,
                47.674757902221806
            ]
        ]
    ]
}$anystr$);

SELECT * FROM cd_create_project_extents(1,$anystr${
        "type": "Polygon",
        "coordinates": [
          [
            [
              -122.32815563678741,
              47.67643748686037
            ],
            [
              -122.32797861099243,
              47.676426651003716
            ],
            [
              -122.32801079750062,
              47.67608712635533
            ],
            [
              -122.3282253742218,
              47.676101574257714
            ],
            [
              -122.32826292514801,
              47.6761774256796
            ],
            [
              -122.32830047607422,
              47.6761774256796
            ],
            [
              -122.32830584049225,
              47.67611963413007
            ],
            [
              -122.32854187488556,
              47.67613047005046
            ],
            [
              -122.32854723930359,
              47.67619909749417
            ],
            [
              -122.3286384344101,
              47.67619909749417
            ],
            [
              -122.32864379882811,
              47.67615575385601
            ],
            [
              -122.32894957065582,
              47.67615214188456
            ],
            [
              -122.32888519763945,
              47.67660724832084
            ],
            [
              -122.3286759853363,
              47.67660363638061
            ],
            [
              -122.32867062091827,
              47.67654584530315
            ],
            [
              -122.32861161231993,
              47.67653862141396
            ],
            [
              -122.32860088348387,
              47.676480830264474
            ],
            [
              -122.32850968837738,
              47.676480830264474
            ],
            [
              -122.32851505279541,
              47.676513337793956
            ],
            [
              -122.32845067977904,
              47.67652056168664
            ],
            [
              -122.32843995094298,
              47.67659280055846
            ],
            [
              -122.3282092809677,
              47.67658918861726
            ],
            [
              -122.3282092809677,
              47.67652417363259
            ],
            [
              -122.32814490795135,
              47.676513337793956
            ],
            [
              -122.32815563678741,
              47.67643748686037
            ]
          ]
        ]
      }$anystr$);

  SELECT * FROM cd_create_project_extents(1,$anystr${
        "type": "Polygon",
        "coordinates": [
          [
            [
              -68.15128326416014,
              -16.484814448981634
            ],
            [
              -68.16450119018555,
              -16.48629589040128
            ],
            [
              -68.16999435424805,
              -16.488106525630386
            ],
            [
              -68.14355850219727,
              -16.52958189119469
            ],
            [
              -68.11918258666992,
              -16.515922336997207
            ],
            [
              -68.11763763427734,
              -16.499463760239838
            ],
            [
              -68.11952590942383,
              -16.48892953604507
            ],
            [
              -68.1155776977539,
              -16.472468663088076
            ],
            [
              -68.10081481933594,
              -16.460615968545216
            ],
            [
              -68.11935424804688,
              -16.464073079315213
            ],
            [
              -68.13446044921875,
              -16.464896191841508
            ],
            [
              -68.12896728515625,
              -16.487118908513903
            ],
            [
              -68.1452751159668,
              -16.47691323665894
            ],
            [
              -68.14836502075195,
              -16.464402324745098
            ],
            [
              -68.15248489379883,
              -16.464402324745098
            ],
            [
              -68.15128326416014,
              -16.484814448981634
            ]
          ]
        ]
      }$anystr$);

 SELECT * FROM cd_create_project_extents(1,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);

 select * from project;
 select * from project_extents;
 select * from relationship_geometry
 select * from relationship
******************************************************************/

CREATE OR REPLACE FUNCTION cd_create_project_extents(project_id int, geojson text)
  RETURNS INTEGER AS $$
  DECLARE

  p_id int;
  pe_id int; -- new project extents id
  data_geojson character varying; -- geojson paramater
  data_geom geometry;
  cd_geom_type character varying;

  BEGIN

    IF ($1 IS NOT NULL AND $2 IS NOT NULL) THEN

        data_geojson = geojson::text;

        SELECT INTO p_id id FROM project WHERE id = $1;

        IF (cd_validate_project(p_id)) THEN

            -- get geom form GEOJSON
            SELECT INTO data_geom * FROM ST_SetSRID(ST_GeomFromGeoJSON(data_geojson),4326);

            SELECT INTO cd_geom_type * FROM ST_GeometryType(data_geom); -- get geometry type (ST_Polygon, ST_Linestring, or ST_Point)

            IF data_geom IS NOT NULL AND cd_geom_type = 'ST_Polygon' THEN
                INSERT INTO project_extents (project_id,geom) VALUES (p_id, data_geom) RETURNING id INTO pe_id;
                RETURN pe_id;
            ELSE
                RAISE NOTICE 'Invalid GeoJSON';
                RETURN pe_id;
            END IF;

        ELSE
            RAISE NOTICE 'Invalid Project id';
            RETURN pe_id;
        END IF;

    ELSE
        RAISE NOTICE 'Relationship id and Geometry required';
        RETURN pe_id;
    END IF;

  END;

$$ LANGUAGE plpgsql VOLATILE;