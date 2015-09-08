-- CADASTA DATABASE V1

-- CREATE DATABASE cadasta_v1;

-- DROP SCHEMA PUBLIC CASCADE;
-- CREATE SCHEMA PUBLIC;

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE gender AS ENUM ('Male', 'Female');
CREATE TYPE json_result AS (response json);

-- Normalize?
CREATE TYPE land_use AS ENUM ('Commercial', 'Residential');
CREATE TYPE id_type AS ENUM ('Drivers License, Passport');

-- CKAN organizaiton
CREATE TABLE organization (
    id serial primary key not null,
    title character varying,
    description character varying,
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
    ckan_id character varying,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Project table holds CKAN project extents
CREATE TABLE project_extents (
    id int primary key not null,
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
    id int primary key not null,
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
    type character varying,
    url character varying,
    description character varying,
    active boolean default true,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- Party table
CREATE TABLE party (
    id serial primary key not null,
    project_id int not null references project(id),
    first_name character varying not null,
    last_name character varying not null,
    type character varying,
    title character varying,
    description character varying,
    contact character varying,
    num_members int,
    legal_states character varying,
    id_type id_type,
    city character varying,
    state character varying,
    zip character varying,
    email character varying,
    martial_status character varying,
    edu_level character varying,
    occupation character varying,
    gender gender,
    DOB date,
    active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
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

INSERT INTO tenure_type (type) VALUES ('own');
INSERT INTO tenure_type (type) VALUES ('lease');
INSERT INTO tenure_type (type) VALUES ('occupy');
INSERT INTO tenure_type (type) VALUES ('informal occupy');

CREATE TABLE spatial_source (
    id serial primary key not null,
    type character varying not null,
    sys_delete boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

INSERT INTO spatial_source (type) VALUES ('survey_sketch');
INSERT INTO spatial_source (type) VALUES ('digitized');
INSERT INTO spatial_source (type) VALUES ('recreational_gps');
INSERT INTO spatial_source (type) VALUES ('survey_grade_gps');

-- Parcel Table
-- Parcel Geometry table
CREATE TABLE parcel (
    id serial primary key not null,
    project_id int not null references project(id),
    spatial_source int references spatial_source(id) not null, -- required?
    user_id character varying not null,
    area numeric,  -- area of polygon
    length numeric,  -- lengthof linestring
    geom geometry,
    land_use land_use,
    gov_pin character varying,
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

-- Relationship Geometry table
CREATE TABLE relationship_geometry (
    id serial primary key not null,
    geom geometry not null,
    sys_delete boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);

-- relationship table
-- resource will be attached to relationship
CREATE TABLE relationship (
    id serial primary key not null,
    project_id int not null references project(id),
    parcel_id int references parcel(id) not null,
    party_id int references party(id),
    geom_id int references relationship_geometry (id),
    tenure_type int references tenure_type (id) not null,
    acquired_date date,
    how_acquired character varying,
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
    parent_id int references relationship(id), --  in case of split, reltionship id is relationship id form which the relaltionship is derived from
    expiration_date timestamp,
    description character varying not null,
    date_modified date not null,
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
    origin_id int not null, --  in case of split, the origin id will always be the parcel id of the original parcel
    parent_id int references parcel(id), -- in case of split, parent id is parcel id from which the parcel is derived from
    version int default 1 not null, -- version of the original parcel
    description character varying not null,
    date_modified date not null,
    active boolean default true not null,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp with time zone NOT NULL DEFAULT current_timestamp,
    created_by integer,
    updated_by integer
);