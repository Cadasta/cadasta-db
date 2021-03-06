-- CADASTA DATABASE V1

-- CREATE DATABASE cadasta_v1;

-- DROP SCHEMA PUBLIC CASCADE;
-- CREATE SCHEMA PUBLIC;

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE TYPE json_result AS (response json);

-- ENUM types
CREATE TYPE land_use AS ENUM ('commercial', 'residential', 'agriculture', 'grazing', 'community land', 'other');
CREATE TYPE party_type AS ENUM ('individual', 'group');

-- CKAN organizaiton
CREATE TABLE organization (
    id serial primary key not null,
    title character varying,
    description character varying,
    ckan_name character varying unique,
    ckan_id character varying unique,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- CKAN project
CREATE TABLE project (
    id serial primary key not null,
    organization_id int not null references organization(id),
    title character varying,
    description character varying,
    ckan_name character varying unique,
    ckan_id character varying unique,
    ona_api_key character varying unique,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Project table holds CKAN project extents
CREATE TABLE project_extents (
    id serial primary key not null,
    project_id int not null references project(id),
    geom geometry,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Project WMS/Tile layers
CREATE TABLE project_Layers (
    id serial primary key not null,
    project_id int not null references project(id),
    layer_url character varying not null,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- resource table holds all resources
CREATE TABLE resource (
    id serial primary key not null,
    project_id int not null references project(id),
    url character varying unique,
    file_name character varying,
    type character varying,
    description character varying,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- resource <--> project junction table
CREATE TABLE resource_project (
    project_id int references project(id),
    resource_id int references resource(id)
);

-- Party table
CREATE TABLE party (
    id serial primary key not null,
    project_id int not null references project(id),
    full_name character varying,
    group_name character varying,
    type party_type not null,
    title character varying,
    description character varying,
    contact character varying,
    num_members int,
    legal_states character varying,
    national_id character varying,
    city character varying,
    state character varying,
    zip character varying,
    email character varying,
    martial_status character varying,
    edu_level character varying,
    occupation character varying,
    gender character varying,
    DOB timestamp with time zone,
    validated boolean,
    time_validated timestamp with time zone,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer,
    check (full_name IS NOT NULL OR group_name IS NOT NULL)
);

-- Resource <--> party junction table
CREATE TABLE resource_party (
    party_id int references party(id),
    resource_id int references resource(id)
);

CREATE TABLE restriction (
    id serial primary key not null,
    description character varying,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

CREATE TABLE responsibility (
    id serial primary key not null,
    description character varying,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

CREATE TABLE "right" (
    id serial primary key not null,
    description character varying,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Tenure Type table
CREATE TABLE tenure_type (
    id serial primary key not null,
    type character varying not null,
    description character varying,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

INSERT INTO tenure_type (type) VALUES ('indigenous land rights');
INSERT INTO tenure_type (type) VALUES ('joint tenancy');
INSERT INTO tenure_type (type) VALUES ('tenancy in common');
INSERT INTO tenure_type (type, description) VALUES ('undivided co-ownership','general term covering strata title and condominiums');
INSERT INTO tenure_type (type) VALUES ('easement');
INSERT INTO tenure_type (type) VALUES ('equitable servitude');
INSERT INTO tenure_type (type, description) VALUES ('mineral rights', 'includes oil & gas');
INSERT INTO tenure_type (type, description) VALUES ('water rights', 'collective term for bundle of rights possible');
INSERT INTO tenure_type (type, description) VALUES ('concessionary rights','non-mineral');
INSERT INTO tenure_type (type) VALUES ('carbon rights');

 INSERT INTO tenure_type (type) VALUES ('freehold');
 INSERT INTO tenure_type (type, description) VALUES ('long term leasehold', '10+ years');
 INSERT INTO tenure_type (type) VALUES ('leasehold');
 INSERT INTO tenure_type (type) VALUES ('customary rights');
 INSERT INTO tenure_type (type, description) VALUES ('occupancy', 'no documented rights');
 INSERT INTO tenure_type (type, description) VALUES ('tenancy','documented sub-lease');
 INSERT INTO tenure_type (type) VALUES ('hunting/fishing/harvest rights');
 INSERT INTO tenure_type (type) VALUES ('grazing rights');

CREATE TABLE spatial_source (
    id serial primary key not null,
    type character varying not null,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

INSERT INTO spatial_source (type) VALUES ('survey sketch');
INSERT INTO spatial_source (type) VALUES ('digitized');
INSERT INTO spatial_source (type) VALUES ('survey coordinates');
INSERT INTO spatial_source (type) VALUES ('recreational gps');
INSERT INTO spatial_source (type) VALUES ('survey grade gps');

-- Parcel Table
-- Parcel Geometry table
CREATE TABLE parcel (
    id serial primary key not null,
    project_id int not null references project(id),
    spatial_source int references spatial_source(id) not null, -- required?
    user_id character varying,
    area numeric,  -- area of polygon
    length numeric,  -- lengthof linestring
    geom geometry,
    land_use land_use,
    gov_pin character varying,
    validated boolean,
    time_validated timestamp with time zone,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- resource <--> Parcel junction table
CREATE TABLE resource_parcel (
    parcel_id int references parcel(id),
    resource_id int references resource(id)
);

-- relationship table
-- resource will be attached to relationship
CREATE TABLE relationship (
    id serial primary key not null,
    project_id int not null references project(id),
    parcel_id int references parcel(id) not null,
    party_id int references party(id) not null,
    geom geometry,
    area numeric,  -- area of polygon
    length numeric,  -- lengthof linestring
    tenure_type int references tenure_type (id) not null,
    acquired_date timestamp with time zone,
    how_acquired character varying,
    validated boolean,
    time_validated timestamp with time zone,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- resource <--> Parcel junction table
CREATE TABLE resource_relationship (
    relationship_id int references relationship(id),
    resource_id int references resource(id)
);

CREATE TABLE restriction_relationship (
    restriction_id int not null references restriction (id),
    relationship_id int not null references relationship (id)
);

CREATE TABLE responsibility_relationship (
    responsibility_id int not null references responsibility (id),
    relationship_id int not null references relationship (id)
);

CREATE TABLE right_relationship (
    right_id int not null references "right" (id),
    relationship_id int not null references relationship (id)
);

CREATE TABLE relationship_history (
    id serial primary key not null,
    relationship_id int references relationship(id) not null,
    origin_id int references relationship(id) not null, -- in case of split, the origin id will always be the relationship id of the original relationship
    version int default 1 not null, -- verison of the original relationship
    parent_id int references relationship(id), --  in case of split, parent id is relationship id form which the relaltionship is derived from
    expiration_date timestamp with time zone,
    description character varying,

    parcel_id int references parcel(id) not null,
    party_id int references party(id) not null,
    geom geometry,
    area numeric,  -- area of polygon
    length numeric,  -- lengthof linestring
    tenure_type int references tenure_type (id) not null,
    acquired_date timestamp with time zone,
    how_acquired character varying,

    active boolean default true not null,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Parcel history table
CREATE TABLE parcel_history (
    id serial primary key not null,
    parcel_id int references parcel(id) not null,
    origin_id int references parcel(id) not null, --  in case of split, the origin id will always be the parcel id of the original parcel
    parent_id int references parcel(id), -- in case of split, parent id is parcel id from which the parcel is derived from
    version int default 1 not null, -- version of the original parcel
    description character varying not null,
    spatial_source int references spatial_source(id) not null, -- required?
    user_id character varying,
    area numeric,  -- area of polygon
    length numeric,  -- lengthof linestring
    geom geometry,
    land_use land_use,
    gov_pin character varying,
    active boolean default true not null,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

CREATE INDEX idx_parcel_geom ON parcel USING GIST (geom);
CREATE INDEX idx_parcel_history_geom ON parcel_history USING GIST (geom);
CREATE INDEX idx_relationship_geom ON relationship USING GIST (geom);
CREATE INDEX idx_relationship_history_geom ON relationship_history USING GIST (geom);
CREATE INDEX idx_project_extents_geom ON project_extents USING GIST (geom);
