/*************************************************
    Add views to DB

*************************************************/
--- DROP VIEW show_relationships;
--- DROP VIEW show_activity;
--- DROP VIEW show_parcels_list;

-- Show all relationships
CREATE OR replace view show_relationships AS
SELECT r.id AS relationship_id, t.type AS relationship_type, parcel.id AS parcel_id, project.id AS project_id, project.ckan_id, s.type AS spatial_source, project.title as project_title, COALESCE(rg.geom,parcel.geom) as geom,
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
(SELECT 'parcel' AS activity_type, parcel.id, s.type, NULL AS name,NULL AS parcel_id, parcel.time_created, parcel.project_id, project.ckan_id
FROM parcel, spatial_source s, project
WHERE parcel.spatial_source = s.id
AND parcel.project_id = project.id
UNION all
SELECT 'party', party.id, NULL, first_name || ' ' || lASt_name, NULL, party.time_created, party.project_id, project.ckan_id
FROM party, project
WHERE party.project_id = project.id
UNION all
SELECT 'relationship', r.id, t.type, p.first_name || ' ' || p.lASt_name AS owners, par.id::text AS parcel_id, r.time_created, r.project_id, pro.ckan_id
FROM relationship r, tenure_type t, party p, parcel par, project pro
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id
AND r.project_id = pro.id)
AS foo
Order BY time_created DESC;

-- Parcel list with relationship count
CREATE OR REPLACE VIEW show_parcels_list AS
SELECT p.id, pro.id AS project_id, pro.ckan_id, p.time_created, p.area, p.length, array_agg(t.type) as tenure_type, count(r.id) as num_relationships, p.active
FROM parcel p, relationship r, tenure_type t, project pro
WHERE r.parcel_id = p.id
AND p.project_id = pro.id
AND r.project_id = pro.id
AND r.tenure_type = t.id
AND p.active = true
AND r.active = true
GROUP BY p.id, pro.id;

-- Relationship History View
CREATE OR replace view show_relationship_history AS
SELECT 
project.id as project_id, project.ckan_id,
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

-- Parcel Resource Views
CREATE VIEW show_parcel_resources AS
SELECT r.project_id, pro.ckan_id, rp.parcel_id, rp.resource_id, r.type, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, parcel p, resource_parcel rp, project pro
where rp.parcel_id = p.id
and rp.resource_id = r.id
and r.project_id = pro.id;


-- Party Resource Views
CREATE VIEW show_party_resources AS
SELECT r.project_id, pro.ckan_id, rp.party_id, rp.resource_id, r.type, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, party p, resource_party rp, project pro
where rp.party_id = p.id
and rp.resource_id = r.id
and r.project_id = pro.id;


-- Relationship Resource Views
CREATE VIEW show_relationship_resources AS
SELECT r.project_id, pro.ckan_id, rr.relationship_id, rr.resource_id, r.type, r.url, r.description, r.active, r.sys_delete, r.time_created, r.time_updated, r.created_by, r.updated_by
from resource r, relationship rel, resource_relationship rr, project pro
where rr.relationship_id = rel.id
and rr.resource_id = r.id
and r.project_id = pro.id;

-- Project Extents
CREATE VIEW show_project_extents AS
SELECT p.id, p.ckan_id, p.organization_id, p.title, pe.geom, p.ckan_id, p.active, p.sys_delete, p.time_created, p.time_updated, p.created_by, p.updated_by
FROM project_extents pe right join project p on pe.project_id = p.id;
