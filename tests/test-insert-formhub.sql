CREATE TYPE json_result AS (response json);

show data_directory;

DROP TRIGGER IF EXISTS cd_process_data ON raw_form;
CREATE TRIGGER cd_process_data AFTER INSERT ON raw_form
    FOR EACH ROW EXECUTE PROCEDURE cd_process_data();

select * from json_each_text('{"type": "note", "name": "project_id", "label": "1"}')

truncate table survey cascade;
truncate table respondent cascade;
truncate table raw_data cascade;
truncate table raw_form cascade;
truncate table person cascade;
truncate table parcel cascade;
truncate table response cascade;

select * from question;
truncate table survey cascade
select * from q_group
select * from section
select * from option
select * from type
select * from survey
select * from quote_literal('')
SELECT * from type


SELECT * FROM cd_import_data_json($anystr$[{"_notes":[],"form_completed":"2013-01-01T09:47:08.069+06","_bamboo_dataset_id":"","_tags":[],"_xform_id_string":"buildings_example","_geolocation":[null,null],"_duration":133,"osm_building":"OSMWay323704347.osm","meta/instanceID":"uuid:a49c80b1-9389-43c5-b660-bf3d86cce171","end":"2013-01-01T09:47:08.065+06","start":"2013-01-01T09:44:55.009+06","_status":"submitted_via_web","today":"2013-01-01","_uuid":"a49c80b1-9389-43c5-b660-bf3d86cce171","_submitted_by":null,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26","fieldpaper_id":"2367","_submission_time":"2015-05-13T16:46:24","_version":"201505120508","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/396017?filename=dkunce/attachments/OSMWay323704347.osm&suffix=medium","download_url":"/api/v1/files/396017?filename=dkunce/attachments/OSMWay323704347.osm","filename":"dkunce/attachments/OSMWay323704347.osm","instance":2143277,"small_download_url":"/api/v1/files/396017?filename=dkunce/attachments/OSMWay323704347.osm&suffix=small","id":396017,"xform":51126}],"deviceid":"353106061525257","_id":2143277},{"_notes":[],"form_completed":"2013-01-01T09:47:57.882+06","_bamboo_dataset_id":"","_tags":[],"_xform_id_string":"buildings_example","_geolocation":[null,null],"_duration":279,"osm_building":"OSMWay323704347.osm","meta/instanceID":"uuid:68a8f242-b826-472b-b546-e42ae7ac9f7a","end":"2013-01-01T09:47:57.882+06","start":"2013-01-01T09:43:18.475+06","_status":"submitted_via_web","today":"2013-01-01","_uuid":"68a8f242-b826-472b-b546-e42ae7ac9f7a","_submitted_by":null,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26","fieldpaper_id":"B1","_submission_time":"2015-05-13T16:46:23","_version":"201505120508","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/396016?filename=dkunce/attachments/OSMWay323704347.osm&suffix=medium","download_url":"/api/v1/files/396016?filename=dkunce/attachments/OSMWay323704347.osm","filename":"dkunce/attachments/OSMWay323704347.osm","instance":2143276,"small_download_url":"/api/v1/files/396016?filename=dkunce/attachments/OSMWay323704347.osm&suffix=small","id":396016,"xform":51126}],"deviceid":"353106061525257","_id":2143276},{"_notes":[],"form_completed":"2013-01-01T09:47:36.276+06","_bamboo_dataset_id":"","_tags":[],"_xform_id_string":"buildings_example","_geolocation":[null,null],"_duration":528,"osm_building":"OSMWay323704347.osm","meta/instanceID":"uuid:8ec157e0-401a-4579-9155-6ef2a7072994","end":"2013-01-01T09:47:36.272+06","start":"2013-01-01T09:38:48.670+06","_status":"submitted_via_web","today":"2013-01-01","_uuid":"8ec157e0-401a-4579-9155-6ef2a7072994","_submitted_by":null,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26","fieldpaper_id":"D1","_submission_time":"2015-05-13T16:46:22","_version":"201505120508","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/396015?filename=dkunce/attachments/OSMWay323704347.osm&suffix=medium","download_url":"/api/v1/files/396015?filename=dkunce/attachments/OSMWay323704347.osm","filename":"dkunce/attachments/OSMWay323704347.osm","instance":2143274,"small_download_url":"/api/v1/files/396015?filename=dkunce/attachments/OSMWay323704347.osm&suffix=small","id":396015,"xform":51126}],"deviceid":"353106061525257","_id":2143274},{"_notes":[],"form_completed":"2013-01-01T09:55:29.051+06","_bamboo_dataset_id":"","_tags":[],"_xform_id_string":"buildings_example","_geolocation":[null,null],"_duration":349,"osm_building":"OSMWay343466290.osm","meta/instanceID":"uuid:ea011f82-d84e-421d-875c-17e4ae3d89cb","end":"2013-01-01T09:55:29.046+06","start":"2013-01-01T09:49:40.272+06","_status":"submitted_via_web","today":"2013-01-01","_uuid":"ea011f82-d84e-421d-875c-17e4ae3d89cb","_submitted_by":null,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26","fieldpaper_id":"A1","_submission_time":"2015-05-13T06:50:18","_version":"201505120508","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/395483?filename=dkunce/attachments/OSMWay343466290.osm&suffix=medium","download_url":"/api/v1/files/395483?filename=dkunce/attachments/OSMWay343466290.osm","filename":"dkunce/attachments/OSMWay343466290.osm","instance":2135544,"small_download_url":"/api/v1/files/395483?filename=dkunce/attachments/OSMWay343466290.osm&suffix=small","id":395483,"xform":51126}],"deviceid":"353106061525133","_id":2135544},{"_notes":[],"form_completed":"2013-01-01T09:47:24.767+06","_id":2135543,"end":"2013-01-01T09:47:24.764+06","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/395482?filename=dkunce/attachments/OSMWay343466280.osm&suffix=medium","download_url":"/api/v1/files/395482?filename=dkunce/attachments/OSMWay343466280.osm","filename":"dkunce/attachments/OSMWay343466280.osm","instance":2135543,"small_download_url":"/api/v1/files/395482?filename=dkunce/attachments/OSMWay343466280.osm&suffix=small","id":395482,"xform":51126}],"deviceid":"353106061525133","_submission_time":"2015-05-13T06:50:17","_uuid":"6b5fc9a8-3d9a-4cfa-ba8f-b2bc7f2ad1cb","_bamboo_dataset_id":"","_tags":[],"_geolocation":[null,null],"start":"2013-01-01T09:45:46.110+06","_version":"201505120508","_submitted_by":null,"osm_building":"OSMWay343466280.osm","_xform_id_string":"buildings_example","today":"2013-01-01","_status":"submitted_via_web","meta/instanceID":"uuid:6b5fc9a8-3d9a-4cfa-ba8f-b2bc7f2ad1cb","_duration":98,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26"},{"_notes":[],"form_completed":"2013-01-01T09:44:39.690+06","_bamboo_dataset_id":"","_tags":[],"_xform_id_string":"buildings_example","_geolocation":[null,null],"_duration":1017,"osm_building":"OSMWay340309368.osm","meta/instanceID":"uuid:c9099efa-69b1-40b5-8405-dd708f9ba847","end":"2013-01-01T09:44:39.687+06","start":"2013-01-01T09:27:42.052+06","_status":"submitted_via_web","today":"2013-01-01","_uuid":"c9099efa-69b1-40b5-8405-dd708f9ba847","_submitted_by":null,"formhub/uuid":"9bd924b24a5a46cd8cc8c0abb195fd26","fieldpaper_id":"A1","_submission_time":"2015-05-13T06:50:15","_version":"201505120508","_attachments":[{"mimetype":"text/xml","medium_download_url":"/api/v1/files/395480?filename=dkunce/attachments/OSMWay340309368.osm&suffix=medium","download_url":"/api/v1/files/395480?filename=dkunce/attachments/OSMWay340309368.osm","filename":"dkunce/attachments/OSMWay340309368.osm","instance":2135541,"small_download_url":"/api/v1/files/395480?filename=dkunce/attachments/OSMWay340309368.osm&suffix=small","id":395480,"xform":51126}],"deviceid":"353106061525133","_id":2135541}]$anystr$)

'/Users/nick/code/cadasta-db/form-hub-surveys/bs-geo-form.json'

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-geo-form.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-geo-data.json');

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-form.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-data.json');

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56_data.json');

(SELECT json_array_elements(value) as json FROM json_each((select json from raw_form where id = 5)) WHERE key = 'children')

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56.json');

select * from respondent
select * from raw_data
select * from survey
select * from raw_form
select * from section
select * from type
select * from person
select * from question
select * from response
select * from parcel
select * from parcel_history
select * from relationship

SELECT * FROM json_array_elements((select json from raw_data where id = 1))

ALTER TABLE relationship ALTER COLUMN acquired_date SET DATA TYPE date

select json from raw_form where id = 34


select * FROM json_cleanup('{"relevant": "selected(${applicant_marital_status}, 'married')"}');

select replace("{"relevant": "selected(${applicant_marital_status}, 'married')"}', ', ''");

select * from import_form_json ('{"name": "Basic-survey-prototype7","title": "Basic Cadasta Survey Prototype 7"}')

CREATE OR REPLACE FUNCTION import_form_json(form_json json)
RETURNS SETOF json_result AS $$
DECLARE
  raw_form_id int;
BEGIN

  INSERT INTO raw_form (json) VALUES (form_json::json) RETURNING id INTO raw_form_id;

  IF raw_form_id IS NOT NULL THEN
    RAISE NOTICE 'Succesfully inserted raw json form, id: %', raw_form_id;
  END IF;

END;$$ language plpgsql;
