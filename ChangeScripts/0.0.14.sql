/******************************************************************
 Change Script 0.0.10
 Date: 11/16/15

 1. Add validated column to party list
 2. Add dateTime to the field data question type table
 3. Truncate field data table

 ******************************************************************/

DROP VIEW show_parties;
CREATE OR REPLACE VIEW show_parties AS
select pro.id as project_id, p.id, count(r.id) as num_relationships, p.group_name, full_name, type,  p.validated, p.national_id, p.gender, p.dob, p.description as notes, p.active, p.time_created, p.time_updated
from party p left join relationship r on r.party_id = p.id, project pro
where p.project_id = pro.id
group by p.id, pro.id;

INSERT INTO type (name, has_options) VALUES ('dateTime', FALSE);

DROP VIEW show_activity;
CREATE OR REPLACE VIEW show_activity AS
SELECT * FROM
(SELECT 'parcel' AS activity_type, parcel.id, s.type, NULL AS name,NULL AS parcel_id, parcel.time_created, parcel.project_id
FROM parcel, spatial_source s, project
WHERE parcel.spatial_source = s.id
AND parcel.project_id = project.id
UNION all
SELECT 'parcel_history' AS activity_type, ph.parcel_id, s.type, NULL AS name,NULL AS parcel_id, ph.time_created, p.project_id
FROM parcel_history ph, spatial_source s, project ,parcel p
WHERE ph.spatial_source = s.id
AND p.project_id = project.id
AND ph.parcel_id = p.id
AND version > 1
UNION all
SELECT 'party', party.id, NULL, COALESCE(full_name, group_name), NULL, party.time_created, party.project_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, COALESCE(p.full_name, p.group_name) AS owners, par.id::text AS parcel_id, r.time_created, r.project_id
FROM relationship r, tenure_type t, party p, parcel par, project pro
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id
AND r.project_id = pro.id
UNION ALL
SELECT 'field_data', f.id, NULL, f.id_string, NULL, f.time_created, f.project_id
FROM field_data f, project p
WHERE f.project_id = p.id
UNION ALL
SELECT 'relationship_history' AS activity_type, r.id, t.type, NULL AS name,NULL AS parcel_id, rh.time_created, r.project_id
FROM relationship_history rh, tenure_type t, project, relationship r
WHERE rh.tenure_type = t.id
AND rh.relationship_id = r.id
AND r.project_id = project.id
AND version > 1)
AS foo
Order BY time_created DESC;

TRUNCATE TABLE field_data CASCADE;