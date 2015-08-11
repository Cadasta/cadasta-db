/*************************************************

    Add views to database

*************************************************/

-- Show all relationships
create or replace view show_relationships as
select r.id as relationship_id, t.type as relationship_type, parcel.id as parcel_id, s.type as spatial_source, geom as parcel_geometry, party.id as party_id, first_name, last_name, r.time_created
from parcel,party,relationship r, spatial_source s, tenure_type t
where r.party_id = party.id
and r.parcel_id = parcel.id
and parcel.spatial_source = s.id
and r.tenure_type = t.id;

-- Show latest parcel, party, & reltionship activity
-- ordered ALL by time created
create or replace view show_activity as
select 'parcel' as activity_type, parcel.id, s.type, parcel.time_created
from parcel, spatial_source s
where parcel.spatial_source = s.id
union all
select 'party', party.id, first_name || ' ' || last_name, time_created
from party
union all
select 'relationship', r.id, t.type, r.time_created
from relationship r, tenure_type t
where r.tenure_type = t.id
order by 4 desc;

