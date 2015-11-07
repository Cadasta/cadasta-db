/******************************************************************
Change Script 0.0.8
Date: 11/05/15

    1. Field Data response view
    2. Add validated to resposne id

******************************************************************/

ALTER TABLE response ADD COLUMN validated boolean DEFAULT FALSE;

CREATE OR REPLACE VIEW show_field_data_responses AS
select f.project_id, r.field_data_id, r.respondent_id, json_object_agg(r.question_id, r.text) as response, r.time_created, r.time_updated
from response r, field_data f
where r.field_data_id = f.id
group by r.respondent_id, r.field_data_id, r.time_created, r.time_updated, f.project_id,r.validated;

CREATE OR REPLACE VIEW show_field_data_questions AS
select distinct(q.id) as question_id, t.name as type, q.name, COALESCE(q.label,q.name) as label, q.field_data_id, f.project_id
from response r, question q, type t, field_data f
where r.question_id = q.id
and q.type_id = t.id
and r.field_data_id = f.id;

CREATE OR REPLACE VIEW show_field_data_list AS
SELECT f.id, f.project_id, count(r.id) as num_submissions, f.user_id, f.id_string, f.form_id, f.name, f.label, f.publish, f.sys_delete, f.time_created, f.time_updated
FROM field_data f left join respondent r on r.field_data_id = f.id
GROUP BY f.id;