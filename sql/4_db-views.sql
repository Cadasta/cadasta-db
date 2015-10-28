/*************************************************
    Add views to DB

*************************************************/
/**
DROP VIEW show_parties;
DROP VIEW show_relationships;
DROP VIEW show_activity;
DROP VIEW show_parcels_list;
DROP VIEW show_relationship_history;
DROP VIEW show_parcel_history;
DROP VIEW show_parcel_resources;
DROP VIEW show_project_resources;
DROP VIEW show_party_resources;
DROP VIEW show_relationship_resources;
DROP VIEW show_project_extents;
**/

-- Show all parties and relationship count
CREATE OR REPLACE VIEW show_parties AS
select pro.id as project_id, p.id, count(r.id) as num_relationships, p.group_name, first_name, last_name, type,  p.active, p.time_created, p.time_updated
from party p left join relationship r on r.party_id = p.id, project pro
where p.project_id = pro.id
group by p.id, pro.id;

-- Show all relationships
CREATE OR replace view show_relationships AS
SELECT r.id AS id, t.type AS tenure_type, r.how_acquired, r.acquired_date, parcel.id AS parcel_id, project.id AS project_id,s.type AS spatial_source, rg.geom as geom,
party.id AS party_id, first_name, lASt_name, r.time_created,r.active, r.time_updated
FROM parcel,party,relationship r left join relationship_geometry rg on r.geom_id = rg.id, spatial_source s, tenure_type t, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

-- Show latest parcel, party, & relationship activity
CREATE OR replace view show_activity AS
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
SELECT 'party', party.id, NULL, first_name || ' ' || lASt_name, NULL, party.time_created, party.project_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, p.first_name || ' ' || p.lASt_name AS owners, par.id::text AS parcel_id, r.time_created, r.project_id
FROM relationship r, tenure_type t, party p, parcel par, project pro
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id
AND r.project_id = pro.id)
AS foo
Order BY time_created DESC;

-- Parcel list with relationship count
CREATE OR REPLACE VIEW show_parcels_list AS
SELECT p.id, pro.id AS project_id, p.time_created, p.area, p.length, array_agg(t.type) as tenure_type, count(r.id) as num_relationships, p.active
FROM parcel p, relationship r, tenure_type t, project pro
WHERE r.parcel_id = p.id
AND p.project_id = pro.id
AND r.project_id = pro.id
AND r.tenure_type = t.id
AND p.active = true
AND r.active = true
GROUP BY p.id, pro.id
UNION
SELECT p.id, pro.id as project_id, p.time_created, p.area, p.length, ARRAY[]::character varying[], 0 as num_relationships, p.active
FROM parcel p left join relationship r on r.parcel_id = p.id, project pro
WHERE p.project_id = pro.id
AND p.active = true
AND p.id IN (select distinct(p.id)
from parcel p left join relationship r on r.parcel_id = p.id
except
select distinct(p.id)
from parcel p join relationship r on r.parcel_id = p.id);

-- Relationship History View
CREATE OR replace view show_relationship_history AS
SELECT 
project.id as project_id,
-- relationship history columns
rh.relationship_id, rh.origin_id, rh.version, rh.parent_id, COALESCE(rg.geom,parcel.geom) as geom,
parcel.id AS parcel_id,
rh.expiration_date, rh.description, rh.date_modified, rh.active, rh.time_created,
rh.time_updated, rh.created_by, rh.updated_by,
-- relationship table columns
t.type AS relationship_type,
s.type AS spatial_source, party.id AS party_id, first_name, last_name
FROM parcel,party,relationship r left join relationship_geometry rg on r.geom_id = rg.id, spatial_source s, tenure_type t, relationship_history rh, project
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND rh.relationship_id = r.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.project_id = project.id
AND r.active = true;

-- Parcel History w/ project_id
CREATE OR REPLACE VIEW show_parcel_history AS
select ph.id, p.project_id, ph.parcel_id, ph.origin_id, ph.parent_id, ph.version, ph.description, ph.date_modified, ph.active, ph.time_created, ph.time_updated, ph.created_by, ph.updated_by
from parcel_history ph, parcel p, project pro
where ph.parcel_id = p.id
and p.project_id = pro.id;

-- Parcel Resource Views
CREATE OR REPLACE VIEW show_parcel_resources AS
SELECT r.project_id, rp.parcel_id, rp.resource_id, r.type, r.file_name, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, parcel p, resource_parcel rp, project pro
where rp.parcel_id = p.id
and rp.resource_id = r.id
and r.project_id = pro.id;


-- Party Resource Views
CREATE OR REPLACE VIEW show_party_resources AS
SELECT r.project_id, rp.party_id, rp.resource_id, r.type, r.file_name, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, party p, resource_party rp, project pro
where rp.party_id = p.id
and rp.resource_id = r.id
and r.project_id = pro.id;


-- Relationship Resource Views
CREATE OR REPLACE VIEW show_relationship_resources AS
SELECT r.project_id, rr.relationship_id, rr.resource_id, r.type, r.file_name, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, relationship rel, resource_relationship rr, project pro
where rr.relationship_id = rel.id
and rr.resource_id = r.id
and r.project_id = pro.id;

-- Project Resource Views
CREATE OR REPLACE VIEW show_project_resources AS
SELECT r.project_id, rp.resource_id, r.type, r.file_name, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, resource_project rp, project pro
where rp.project_id = pro.id
and rp.resource_id = r.id
and r.project_id = pro.id;

-- Project Extents
CREATE OR REPLACE VIEW show_project_extents AS
SELECT p.id, p.organization_id, p.title, pe.geom, p.active, p.sys_delete, p.time_created, p.time_updated, p.created_by, p.updated_by
FROM project_extents pe right join project p on pe.project_id = p.id;

