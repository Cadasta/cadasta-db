-- Create fake org and project until API is wrapped in CKAN API

SELECT * FROM cd_create_organization('demo-organization','Demo Organization',null);
SELECT * FROM cd_create_project((Select id from organization where ckan_id = 'demo-organization'),'demo-project ','Friday Night');

-- ADD resources
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'parcel',1,'http://www.cadasta.org/1/parcel',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'party',1,'http://www.cadasta.org/1/party',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'relationship',1,'http://www.cadasta.org/1/relationship',null, 'test-file.rtf');
--
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'parcel',2,'http://www.cadasta.org/2/parcel',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'party',2,'http://www.cadasta.org/2/party',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'relationship',2,'http://www.cadasta.org/2/relationship',null, 'test-file.rtf');
--
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'parcel',3,'http://www.cadasta.org/3/parcel',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'party',3,'http://www.cadasta.org/3/party',null, 'test-file.rtf');
--SELECT * FROM cd_create_resource((select id FROM project WHERE ckan_id LIKE '%demo_project%'),'relationship',3,'http://www.cadasta.org/3/relationship',null, 'test-file.rtf');

-- Add project extents

  SELECT * FROM cd_create_project_extents((select id FROM project WHERE ckan_id = 'demo-project'),$anystr${
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