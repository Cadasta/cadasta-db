-- CADASTA DATABASE V1

-- CREATE DATABASE cadasta_v1;

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TYPE gender AS ENUM ('Male', 'Female');
CREATE TYPE json_result AS (response json);

-- Normalize?
CREATE TYPE land_use AS ENUM ('Commercial', 'Residential');
CREATE TYPE id_type AS ENUM ('Drivers License, Passport');


-- Project table holds CKAN project extents
CREATE TABLE Project (
    id int primary key not null,
    project_id int not null,
    geom geometry
);

-- Media table holds all media
CREATE TABLE media (
    id serial primary key not null,
    type character varying,
    url character varying,
    description character varying,
    active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- person table
-- FK: person_type id
CREATE TABLE person (
    id serial primary key not null,
    first_name character varying not null,
    last_name character varying not null,
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
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Media <--> Person junction table
CREATE TABLE media_person (
    person_id int references person(id),
    media_id int references media(id)
);

-- group table
CREATE TABLE "group" (
    id serial primary key not null,
    type character varying not null,
    title character varying not null,
    description character varying,
    contact character varying,
    num_members int,
    legal_states character varying,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Media <--> Group junction table
CREATE TABLE media_group (
    group_id int references "group"(id),
    media_id int references media(id)
);

CREATE TABLE restriction (
    id serial primary key not null,
    description character varying,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

CREATE TABLE responsibility (
    id serial primary key not null,
    description character varying,
    active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

CREATE TABLE "right" (
    id serial primary key not null,
    description character varying,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Tenure Type table
CREATE TABLE tenure_type (
    id serial primary key not null,
    type character varying not null,
    description character varying,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

INSERT INTO tenure_type (type) VALUES ('Own');
INSERT INTO tenure_type (type) VALUES ('Lease');
INSERT INTO tenure_type (type) VALUES ('Occupy');
INSERT INTO tenure_type (type) VALUES ('Informal Occupied');

CREATE TABLE spatial_source (
    id serial primary key not null,
    type character varying not null,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
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
    spatial_source int references spatial_source(id) not null, -- required?
    user_id character varying not null,
    area numeric,
    geom geometry,
    land_use land_use,
    gov_pin character varying,
    active boolean default false,
    archived boolean,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Media <--> Parcel junction table
CREATE TABLE media_parcel (
    parcel_id int references parcel(id),
    media_id int references media(id)
);

-- Parcel Geometry table
CREATE TABLE parcel_geometry (
    id serial primary key not null,
    geom geometry not null,
    active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- relationship table
-- media will be attached to relationship
CREATE TABLE relationship (
    id serial primary key not null,
    parcel_id int references parcel(id) not null,
    person_id int references person(id),
    group_id int references "group"(id),
    geom_id int references parcel_geometry (id),
    tenure_type int references tenure_type (id) not null,
    acquired_date date,
    how_acquired character varying,
    archived boolean,
    active boolean default false,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Media <--> Parcel junction table
CREATE TABLE media_relationship (
    relationship_id int references relationship(id),
    media_id int references media(id)
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
    origin_id int references parcel(id) not null, -- in case of split, the origin id will always be the parcel id of the original parcel
    version int default 1 not null,
    parent_id int references parcel(id),
    expiration_date timestamp,
    description character varying not null,
    date_modified date not null,
    active boolean default false not null,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- Parcel history table
CREATE TABLE parcel_history (
    id serial primary key not null,
    parcel_id int references parcel(id) not null,
    origin_id int not null, --  in case of split, the origin id will always be the parcel id of the original parcel
    parent_id int references parcel(id), -- in case of split, parent id is parcel id of the parcel the new parcels are derived from
    version int default 1 not null, -- version of the original parcel
    description character varying not null,
    date_modified date not null,
    active boolean default false not null,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
);

-- create view that shows all data from parcel history, plus each child per parent
