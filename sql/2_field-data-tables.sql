/******************************************************************
  field_data TABLE DEFINITIONS
******************************************************************/

-- field_data
CREATE TABLE "field_data"
(
	"id"			SERIAL				NOT NULL
	,"project_id" int -- CKAN project id
	,"user_id" int -- CKAN user id
	,"parcel_id" int
	,"id_string"		character varying		NOT NULL
	,"name"			character varying
	,"label"		character varying
	,"publish"		boolean				DEFAULT TRUE,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT field_data_id PRIMARY KEY(id)
);

-- resource <--> field_data junction table
CREATE TABLE resource_field_data (
    field_data_id int references field_data(id),
    resource_id int references resource(id)
);

 -- question type
CREATE TABLE "type"
(
	"id"			SERIAL				NOT NULL
	,"name"			character varying
	,"has_options"		boolean,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT type_id PRIMARY KEY(id)
);
-- questions with type "note": these are section headers and closing comments for a field_data; they group questions
-- by subject/area of concern; these question types do not have responses;
CREATE TABLE "section"
(
	"id"			SERIAL				NOT NULL
	,"field_data_id"		integer				NOT NULL	REFERENCES "field_data"(id)
	,"name"			character varying		NOT NULL
	,"label"		character varying
	,"publish"		boolean				DEFAULT TRUE,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT section_id PRIMARY KEY(id)
);
-- questions with type "group" or "repeat": these are groupings of questions for a single specific subject/area;
-- these questions types do not have responses;
CREATE TABLE "q_group"
(
	"id"			SERIAL				NOT NULL
	,"field_data_id"		integer				NOT NULL	REFERENCES "field_data"(id)
	,"section_id"		integer						REFERENCES "section"(id)
	,"parent_id"		integer						REFERENCES "q_group"(id)
	,"name"			character varying		NOT NULL
	,"label"		character varying,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT group_id PRIMARY KEY(id)
);
-- questions with responses
CREATE TABLE "question"
(
	"id"			SERIAL				NOT NULL
	,"name"			character varying		NOT NULL
	,"label"		character varying
	,"field_data_id"		integer				NOT NULL	REFERENCES "field_data"(id)
	,"type_id"		integer						REFERENCES "type"(id)
	,"section_id"		integer						REFERENCES "section"(id)
	,"group_id"		integer						REFERENCES "q_group"(id)
	,"infobox"		boolean						DEFAULT false
	,"tableview"		boolean						DEFAULT false
	,"summary"		boolean						DEFAULT false
	,"filter"		boolean						DEFAULT true
	,"app_label"		character varying
	,"app_column"		character varying
	,"app_plural"		character varying
	,"priority"		integer,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT question_id PRIMARY KEY(id)
);

-- respondent
CREATE TABLE "respondent"
(
	"id"			SERIAL				NOT NULL
	,"field_data_id"		integer						REFERENCES "field_data"(id)
	,"id_string"		character varying
	,"submission_time"	timestamp with time zone,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
	,CONSTRAINT respondent_id PRIMARY KEY(id)
);

-- response to a question from a respondent
CREATE TABLE "response"
(
	"id"			SERIAL				NOT NULL
	,"field_data_id"	integer							REFERENCES "field_data"(id)
	,"respondent_id"	integer						REFERENCES "respondent"(id)
	,"question_id"		integer						REFERENCES "question"(id)
	,"text"			character varying
	,"numeric"		numeric,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
    ,CONSTRAINT response_id PRIMARY KEY(id)
);
-- options for a given question; pertains only to types where has_options = true (select one, select all that apply)
CREATE TABLE "option"
(
	"id"			SERIAL				NOT NULL
	,"question_id"		integer				NOT NULL	REFERENCES "question"(id)
	,"name"			character varying
	,"label"		character varying,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
    ,CONSTRAINT option_id PRIMARY KEY(id)
);
-- the raw json form data
CREATE TABLE "raw_form"
(
	"id"			SERIAL				NOT NULL
	,"json"			json,
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
    ,CONSTRAINT raw_form_id PRIMARY KEY(id)
);
-- the raw json data
CREATE TABLE "raw_data"
(
	"id"			SERIAL				NOT NULL
	,"json"			json,
	,"field_data_id" id references field_data(id),
	active boolean default true,
    time_created timestamp with time zone NOT NULL DEFAULT current_timestamp,
    time_updated timestamp,
    created_by integer,
    updated_by integer
    ,CONSTRAINT raw_data_id PRIMARY KEY(id)
);

/******************************************************************
  LOAD STATIC DATA
******************************************************************/
-- Load FormHub types
INSERT INTO type (name, has_options) VALUES ('text', FALSE); -- free text
INSERT INTO type (name, has_options) VALUES ('end', FALSE);
INSERT INTO type (name, has_options) VALUES ('phonenumber', FALSE);
INSERT INTO type (name, has_options) VALUES ('today', FALSE);
INSERT INTO type (name, has_options) VALUES ('start', FALSE);
INSERT INTO type (name, has_options) VALUES ('deviceid', FALSE);
INSERT INTO type (name, has_options) VALUES ('date', FALSE);
INSERT INTO type (name, has_options) VALUES ('photo', FALSE);
INSERT INTO type (name, has_options) VALUES ('select one', TRUE); -- has a list of options to choose from
INSERT INTO type (name, has_options) VALUES ('geopoint', FALSE); -- spatial
INSERT INTO type (name, has_options) VALUES ('note', FALSE); -- usually a section title, does not have responses
INSERT INTO type (name, has_options) VALUES ('integer', FALSE); -- numeric anwsers only
INSERT INTO type (name, has_options) VALUES ('decimal', FALSE); -- numeric anwsers only
INSERT INTO type (name, has_options) VALUES ('subscriberid', FALSE);
INSERT INTO type (name, has_options) VALUES ('select all that apply', TRUE); -- has a list of options to choose from

INSERT INTO type (name, has_options) VALUES ('repeat', FALSE);
-- the questions in the children object are collected zero to many times
INSERT INTO type (name, has_options) VALUES ('group', FALSE);
-- the questions in the children object are collected as a group