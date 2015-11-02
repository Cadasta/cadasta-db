/******************************************************************
Change Script 0.0.4
Date: 11/2/15

    1. Add new fields to relationship_history view

******************************************************************/
DROP VIEW show_relationship_history;

-- Relationship History View
CREATE OR replace view show_relationship_history AS
SELECT 
project.id as project_id,
-- relationship history columns
rh.relationship_id, rh.origin_id, rh.version, rh.parent_id, rh.geom_id, rh.tenure_type, rh.acquired_date, rh.how_acquired,
parcel.id AS parcel_id,  
rh.expiration_date, rh.description, rh.date_modified, rh.active, rh.time_created, rg.geom, rg.length, rg.area,
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