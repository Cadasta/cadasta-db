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

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-geo-form.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-geo-data.json');

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-form.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/bs-data.json');

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56.json');
SELECT * FROM import_formhub_data_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56_data.json');

(SELECT json_array_elements(value) as json FROM json_each((select json from raw_form where id = 5)) WHERE key = 'children')

SELECT * FROM import_formhub_form_json('/Users/admin/Library/Application Support/Postgres/var-9.4/ftc2013-56.json');

SELECT * FROM json_array_elements($$ $$)

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
select * from relationship_history

SELECT * FROM json_array_elements((select json from raw_data where id = 1))

ALTER TABLE relationship ALTER COLUMN acquired_date SET DATA TYPE date

select json from raw_form where id = 34

select '{"name": "Basic-survey-prototype7","title": "Basic Cadasta Survey Prototype 7"}'::json

select * FROM import_form_json();

CREATE OR REPLACE FUNCTION import_form_json(form_json json)
RETURNS SETOF json_result AS $$
DECLARE
  data_form_json character varying;
  raw_form_id int;
BEGIN

  INSERT INTO raw_form (json) VALUES (data_form_json::json) RETURNING id INTO raw_form_id;

  IF raw_form_id IS NOT NULL THEN
    RAISE NOTICE 'Succesfully inserted raw json form, id: %', raw_form_id;
  END IF;

END;$$ language plpgsql;
