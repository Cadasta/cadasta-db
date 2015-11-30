/******************************************************************
 Change Script 0.0.10
 Date: 11/12/15

 1. Add validated field to parcel/relationship/party
 2. Display validated field on parcel/party/relationship list views

 ******************************************************************/

ALTER TABLE relationship ADD COLUMN validated boolean DEFAULT false;
ALTER TABLE parcel ADD COLUMN validated boolean DEFAULT false;
ALTER TABLE party ADD COLUMN validated boolean DEFAULT false;

DROP VIEW show_parcels_list;
CREATE VIEW show_parcels_list AS
SELECT p.id, pro.id AS project_id, p.time_created, p.area, p.length, p.validated, array_agg(t.type) as tenure_type, count(r.id) as num_relationships, p.active
FROM parcel p, relationship r, tenure_type t, project pro
WHERE r.parcel_id = p.id
AND p.project_id = pro.id
AND r.project_id = pro.id
AND r.tenure_type = t.id
AND p.active = true
AND r.active = true
GROUP BY p.id, pro.id
UNION
SELECT p.id, pro.id as project_id, p.time_created, p.area, p.length, p.validated, ARRAY[]::character varying[], 0 as num_relationships, p.active
FROM parcel p left join relationship r on r.parcel_id = p.id, project pro
WHERE p.project_id = pro.id
AND p.active = true
AND p.id IN (select distinct(p.id)
from parcel p left join relationship r on r.parcel_id = p.id
except
select distinct(p.id)
from parcel p join relationship r on r.parcel_id = p.id);

DROP VIEW show_relationships;
CREATE view show_relationships AS
SELECT r.id AS id, t.type AS tenure_type, r.how_acquired, r.acquired_date, r.validated, parcel.id AS parcel_id, project.id AS project_id,s.type AS spatial_source, r.geom,
party.id AS party_id, full_name, group_name, r.time_created,r.active, r.time_updated
FROM parcel,party,relationship r, spatial_source s, tenure_type t, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

DROP VIEW show_parties;
CREATE VIEW show_parties AS
select pro.id as project_id, p.id, count(r.id) as num_relationships, p.group_name, full_name, type,  p.validated, p.national_id, p.gender, p.dob, p.description as notes, p.active, p.time_created, p.time_updated
from party p left join relationship r on r.party_id = p.id, project pro
where p.project_id = pro.id
group by p.id, pro.id;