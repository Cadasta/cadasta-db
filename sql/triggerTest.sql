/***


Test data load

select * from field_data


***/

SELECT * FROM cd_import_data_json ($anystr$[
    {
        "_notes": [],
        "_bamboo_dataset_id": "",
        "_tags": [],
        "surveyor": "danielbaah",
        "_xform_id_string": "CJF-minimum-la-paz",
        "applicant_name_group": "nme",
        "_attachments": [],
        "_duration": 25.0,
        "meta/instanceID": "uuid:56608b19-a418-47ac-80e7-fd56f50bf910",
        "end": "2015-11-13T16:12:57.397-08",
        "date_land_possession": "2004-03-15T16:12:00.000-08",
        "party_type": "group",
        "start": "2015-11-13T16:12:32.712-08",
        "_geolocation": {
        "type": "Polygon",
        "coordinates": [
          [
            [
              -68.13127398490906,
              -16.498594502708375
            ],
            [
              -68.13038885593414,
              -16.4990522778716
            ],
            [
              -68.13022255897522,
              -16.49927344975331
            ],
            [
              -68.1305605173111,
              -16.499906102809422
            ],
            [
              -68.13167631626129,
              -16.49923744504563
            ],
            [
              -68.13127398490906,
              -16.498594502708375
            ]
          ]
        ]
      },
        "_status": "submitted_via_web",
        "today": "2015-11-13",
        "_uuid": "56608b19-a418-472ac-8011121322e7-fd56f50bf910",
        "means_of_acquire": "inheritance",
        "_submitted_by": "cadasta",
        "formhub/uuid": "122",
        "_submission_time": "2015-11-14T00:12:24",
        "_version": "201511140010",
        "tenure_type": "grazing_rights",
        "deviceid": "3524210335072778",
        "_id": 71
    }
]$anystr$);

    /**

select * from relationship where id in (select relationship_id from respondent where relationship_id is not null) order by time_created desc
select * from response order by time_created desc 
select * from respondent order by time_created desc

select * from relationship order by time_created desc;
    **/