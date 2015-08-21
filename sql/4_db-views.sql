/*************************************************
    Add views to DB

*************************************************/

-- Show all relationships
CREATE OR replace view show_relationships AS
SELECT r.id AS relationship_id, t.type AS relationship_type, parcel.id AS parcel_id, s.type AS spatial_source, geom AS parcel_geometry, party.id AS party_id, first_name, lASt_name, r.time_created
FROM parcel,party,relationship r, spatial_source s, tenure_type t
WHERE r.party_id = party.id
AND r.parcel_id = parcel.id
AND parcel.spatial_source = s.id
AND r.tenure_type = t.id
AND r.active = true;

-- Show latest parcel, party, & relationship activity
CREATE OR replace view show_activity AS
SELECT * FROM (SELECT 'parcel' AS activity_type, parcel.id, s.type, NULL AS name,NULL AS parcel_id, parcel.time_created
FROM parcel, spatial_source s
WHERE parcel.spatial_source = s.id
UNION all
SELECT 'party', party.id, NULL, first_name || ' ' || lASt_name, NULL, time_created
FROM party
UNION all
SELECT 'relationship', r.id, t.type, p.first_name || ' ' || p.lASt_name AS owners, par.id::text AS parcel_id, r.time_created
FROM relationship r, tenure_type t, party p, parcel par
WHERE r.party_id = p.id
AND r.parcel_id = par.id
AND r.tenure_type = t.id) AS foo
Order BY time_CREATEd DESC;

-- Parcel list with relationship count
CREATE OR REPLACE VIEW show_parcel_list AS
SELECT p.id, p.time_created, p.area, count(r.id) as num_relationships
FROM parcel p, relationship r
WHERE r.parcel_id = p.id
AND p.active = true
AND r.active = true
GROUP BY p.id
ORDER BY p.time_created desc;