/******************************************************************
Change Script 0.0.5
Date: 10/30/15

    1. Create show parties view
    2. Add group name to show_party_parcels view

******************************************************************/

DROP VIEW show_parties;
CREATE OR REPLACE VIEW show_parties AS
select pro.id as project_id, p.id, count(r.id) as num_relationships, p.group_name, first_name, last_name, type,  p.active, p.time_created, p.time_updated
from party p left join relationship r on r.party_id = p.id, project pro
where p.project_id = pro.id
group by p.id, pro.id;

-- All parcels associated with parties
CREATE VIEW show_party_parcels AS
SELECT pro.id as project_id, par.id as parcel_id, par.geom, p.id as party_id, r.id as relationship_id
FROM party p, relationship r, parcel par, project pro
where r.party_id = p.id
and p.project_id = pro.id
and par.project_id = pro.id
and r.project_id = pro.id
and r.parcel_id = par.id;