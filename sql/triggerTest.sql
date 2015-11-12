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
"_xform_id_string": "CJF-minimum_Wednesday4",
"applicant_name_group": "Wal mart",
"_attachments": [],
"_duration": 99,
"meta/instanceID": "uuid:72e9b01e-de05-4faf-9eb2-fea2f3b2b458",
"end": "2015-11-11T11:18:27.193-08",
"date_land_possession": "2015-11-02",
"party_type": "group",
"start": "2015-11-11T11:16:48.910-08",
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
"today": "2015-11-11",
"_uuid": "72e9b01e-de05-4faf-39eb2-fea2f3b2b458",
"means_of_acquire": "lease",
"_submitted_by": "cadasta",
"formhub/uuid": "80e4c579b3b84f3918ec179e417a11873",
"_submission_time": "2015-11-11T19:18:04",
"_version": "201511111907",
"tenure_type": "mineral_rights",
"deviceid": "3524210350732778",
"_id": 439
}
]$anystr$);

    /**

select * from relationship where id in (select relationship_id from respondent where relationship_id is not null) order by time_created desc
select * from response order by time_created desc 
select * from respondent order by time_created desc


    **/