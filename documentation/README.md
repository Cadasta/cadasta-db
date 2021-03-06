Cadasta Database Function Reference
===============================


##### Contents

[cd\_create\_parcel](#cd_create_parcel)

[cd\_update\_parcel](#cd_update_parcel)

[cd\_create\_party](#cd_create_party)

[cd\_update\_party](#cd_update_party)

[cd\_create\_relationship](#cd_create_relationship)

[cd\_update\_relationship](#cd_update_relationship)

[cd\_create\_organization](#cd_create_organization)

[cd\_create\_project](#cd_create_project)

[cd\_create\_resource] (#cd_create_resource)

[cd\_create\_relationship_geometry](#cd_create_relationship_geometry)

[cd\_delete\_parcel](#cd_delete_parcel)

[cd\_delete\_parcels](#cd_delete_parcels)

[cd\_archive\_parcel](#cd_archive_parcel)

[cd\_archive\_parcels](#cd_archive_parcels)

[cd\_delete\_relationship](#cd_delete_relationship)

[cd\_delete\_relationships](#cd_delete_relationships)

[cd\_archive\_relationship](#cd_archive_relationship)

[cd\_archive\_relationships](#cd_archive_relationships)

[cd\_validate\_parcel](#cd_validate_parcel)

[cd\_validate\_parcels](#cd_validate_parcels)

[cd\_validate\_relationship](#cd_validate_relationship)

[cd\_validate\_relationships](#cd_validate_relationships)

[cd\_validate\_organization](#cd_validate_organization)

[cd\_validate\_organizations](#cd_validate_organizations)

[cd\_validate\_project](#cd_validate_project)

[cd\_validate\_projects](#cd_validate_projects)

[cd\_import\_data\_json](#cd_import_data_json)

* * * * *

<a name="cd_create_parcel"/>
cd\_create\_parcel
=================

##### Description

Create a new parcel and parcel history.

##### Parameter(s)

1. project\_id (integer) - ***Required***. Cadasta project id 
2. spatial\_source (character varying) – ***Required***.
Options:
    * digitized
    * survey coordinates
    * recreational gps
    * survey grade gps
    * survey sketch
3. geojson - [GeoJSON geometry object](http://geojson.org/geojson-spec.html#geometry-objects)
4.  land\_use (ENUM) - Optional. Type of parcel real estate
Options:
    * commercial
    * residential
    * agriculture
    * grazing
    * community land
    * other
5.  gov\_pin (character varying) - Optional.
6.  history\_description (character varying) - ***Required***. A description of the parcels history

##### Result

Integer. The parcel is successfully created if an integer is returned.

##### Example(s)

-   Add new digitized, commercial parcel to project 1

```SELECT * FROM cd_create_parcel(1, 'digitized', 	$anystr${
           "type": "LineString",
           "coordinates": [
             [
               -121.73326581716537,
               44.5723908536272
             ],
             [
               -121.7331075668335,
               44.57247110339075
             ]
           ]
         }$anystr$, 'commercial', null, 'insert description here');```

14

<a name="cd_update_parcel"/>
cd\_update\_parcel
=================

##### Description

Update a parcel & parcel history

##### Parameter(s)

1. project\_id (integer) - ***Required***. Cadasta project id 
2. parcel\_id (integer) - ***Required***. Cadasta parcel id
3. geojson - [GeoJSON geometry object](http://geojson.org/geojson-spec.html#geometry-objects)
4. spatial\_source (character varying) – Optional. Parcel Spatial Source
Options:
    * digitized
    * recreational gps
    * survey grade gps
    * survey sketch
    * survey coordinates
5.  land\_use (ENUM) - Optional. Type of parcel real estate
Options:
    * commercial
    * residential
    * agriculture
    * grazing
    * community land
    * other
6.  gov\_pin (character varying) - Optional.
7.  description (character varying) - Optional. A description of the parcels history

##### Result

Integer. New parcel history id

##### Example(s)

-   Update parcel 3's geometry

```SELECT * FROM cd_update_parcel (3, $anystr${"type": "LineString","coordinates": [[91.96083984375,43.04889669318],[91.94349609375,42.9511174899156]]}$anystr$, null, null , null, null);```

4

<a name="cd_create_party"/>
cd\_create\_party
=================

##### Description

Create a new party

##### Parameter(s)

1.  project\_id (integer) - ***Required***. Cadasta project id
2.  party\_type (ENUM) - ***Required***. Type of Party
Options: ***Case Sensitive***
    * individual
    * group
3.  full\_name (character varying) – ***Required if group\_name is NULL***.
4.  cd\_group\_name (character varying) - ***Required if first\_name is null***. - Name of Group
5. cd\_gender (character varying) - Optional Gender
6. cd\_dob (date) -  ***YYYY-MM-DD*** Date if Birth
7. description (character varying) - Notes
8. cd\_national_id (character varying) - National ID

##### Result

Integer. The party is successfully created if an integer is returned.

##### Example(s)

-   Create new party Ian O'Guin for project 1

```    SELECT * FROM cd_create_party(1, 'individual', 'Ian', null, 'Male', '4-25-1990', 'my name is Ian', '14u1oakldaCCCC');```

2

-   Create new party group Wal-Mart for project 1

```SELECT * FROM cd_create_party(1, 'group', null, null, 'Wal-Mart', null, null, 'Wal Mart Corporation', null);```

3

<a name="cd_update_party"/>
cd\_update\_party
=================

##### Description

Update a party

##### Parameter(s)

1.  project\_id (integer) - ***Required***. Cadasta project id
2.  party\_id (integer) - ***Required*** Cadasta party id
3.  party\_type (ENUM) - ***Required***. Type of Party
Options: ***Case Sensitive***
    * individual
    * group
4.  full\_name (character varying) – ***Required if group\_name is NULL***.
5.  cd\_group\_name (character varying) - ***Required if first\_name is null***. - Name of Group
6. cd\_gender (character varying) - Optional Gender
7. cd\_dob (date) -  ***YYYY-MM-DD*** Date if Birth
8. description (character varying) - Notes
9. cd\_national_id (character varying) - National ID

##### Result

Integer. The party is successfully updated if party id is returned

##### Example(s)

- Update party 2 - Change to individual, set name to Sam Hernandez
    
```SELECT * FROM cd_update_party(1,2,'individual','Sam','Hernandez',null,'free text gender','1990-04-25','individual description','xxx661222x'); ```   
	
2


- Update party 1 - Change to group, set group_name to Walmart

```SELECT * FROM cd_update_party(1,1,'group',null,null,'Walmart',null,null,'group description','xxx661222x');```

3


<a name="cd_create_relationship"/>
cd\_create\_relationship
=================

##### Description

Create a new relationship and relationship history.

##### Parameter(s)

1.  project\_id (integer) - ***Required***. Project id
2.  parcel\_id (integer) – ***Required***. Parcel id
3.  ckan\_user\_id (integer) – The id associated with the specific CKAN user
4.  party\_id (integer) – ***Required***. Party id
5.  geojson - (character varying) - Optional. Relationship Geometry [GeoJSON geometry object](http://geojson.org/geojson-spec.html#geometry-objects)
6.  tenure\_type (ENUM) - ***Required. Case sensitive*** Tenure type of relationship
Options:
    * indigenous land rights
    * joint tenancy
    * tenancy in common
    * undivided co-ownership
    * easement
    * equitable servitude
    * mineral rights
    * water rights
    * concessionary rights
    * carbon rights
    * freehold
    * long term leasehold
    * leasehold
    * customary rights
    * occupancy
    * tenancy
    * hunting/fishing/harvest rights
    * grazing rights
    
7. acquired\_date (date) - Optional. ***YYYY-MM-DD*** Date of land acquisition
8. how\_acquired (character varying) - Optional. A description of how the land was acquired
9. history\_description (character varying) - A description of the relationships history

##### Result

Integer. The relationship is successfully created if an integer is returned.

##### Example(s)

-   Add new ownership relationship on Project 3 for Party 11 and Parcel 18. Land was acquired on October 22nd, 2009;

```SELECT * FROM cd_create_relationship(3, 18, 11, 24, null, 'own', '10/23/2009', 'Passed Down', '3rd Owner'); ```

14

<a name="cd_update_relationship"/>
cd\_update\_relationship
=================

##### Description

Update a relationship & relationship history

##### Parameter(s)

1. project\_id (integer) - ***Required***. Cadasta project id 
2. relationship\_id (integer) - ***Required***. Cadasta relationship id
3. party\_id (integer) - Optional. Cadasta Party id
4. parcel\_id (integer) - Optional. Cadasta Parcel id
5. geojson - Optional. Relationship geometry [GeoJSON geometry object](http://geojson.org/geojson-spec.html#geometry-objects)
6. tenure\_type (ENUM) - Optional. ***Case sensitive*** Tenure type of relationship
Options:
    * indigenous land rights
    * joint tenancy
    * tenancy in common
    * undivided co-ownership
    * easement
    * equitable servitude
    * mineral rights
    * water rights
    * concessionary rights
    * carbon rights
    * freehold
    * long term leasehold
    * leasehold
    * customary rights
    * occupancy
    * tenancy
    * hunting/fishing/harvest rights
    * grazing rights
    
7.  acquired\_date (Date) - Optional. ***YYYY-MM-DD*** Date of tenure acquisition
8.  how\_acquired (character varying) - Optional. A description of how acquisition was acquired
9.  description (character varying) - Optional. A description of the relationships history

##### Result

Integer. New relationship history id

##### Example(s)

-   Update relationship 1's tenure type, how acquired, and history description

```SELECT * FROM cd_update_relationship(1,1,null,null,null,'occupy',null, 'taken over by government', 'informed in the mail');```

13

<a name="cd_create_organization"/>
cd\_create\_organization
=================

##### Description

Create Organization

##### Parameter(s)

1. ckan\_name (character varying) - ***Required (Unique)***.  CKAN organization name
2. ckan\_id (character varying) – ***Required (Unique)***. CKAN organization id
3. title (character varying) – ***Required***. Organization title
4. description (character varying) - Optional. Organization description

##### Result

Integer. The organization is successfully created if an integer is returned.

##### Example(s)

-   Create new organization

```SELECT * FROM cd_create_organization('grow','123fadsaa', 'GROW Project', 'Created in response to GROW');```

3

<a name="cd_create_project"/>
cd\_create\_project
=================

##### Description

Create Project for an Organization

##### Parameter(s)

1.  organization\_id (integer) – ***Required***. Project id
2.  ckan\_id (character varying) – ***Required***. CKAN project id
3.  ckan\_name (character varying) - ***Required***. CKAN project name
4.  title (character varying) – ***Required***. Project title
5.  description (character varying) -- Project description
6.  api_key (character varying) -- ONA API Key

##### Result

Integer. The project is successfully created if an integer is returned.

##### Example(s)

-   Create new Project 'Medellin Pilot' for Cadasta Organization (id: 6)

```     SELECT * FROM cd_create_project(6,'34282jhsjjad839011', 'Medellin', 'Medellin Pilot', 'description', null); ```

2

<a name="cd_create_resource"/>
cd\_create\_resource
=================

##### Description

Create resource for a project, party, parcel, or relationship

##### Parameter(s)

1.  project\_id (integer) – ***Required***. Project id
2.  resource\_type (character varying) – ***Required***.
Options:
    * project
    * parcel
    * party
    * relationship
3.  resource\_type\_id (integer) – ***Required***. id of resource\_type
4.  url - ***Required*** resource url
5.  description - resource description
6.  filename - ***Required*** resource filename

##### Result

Integer. The resource is successfully created if an integer is returned.

##### Example(s)

- Create new resource for relationship 30 in project 3

``` SELECT * FROM cd_create_resource(3,'relationship',30,'http://www.cadasta.org/30/relationship','Bird's eye view of parcel, 'birdseye.txt'); ```

52

<a name="cd_create_relationship_geometry"/>
cd\_create\_relationship\_geometry
=================

##### Description

Create Relationship geometry

##### Parameter(s)

1.  project_id (integer) ***Required***. Project id
2.  relationship\_id (integer) – ***Required***. Relationship id
3.  geojson (text) – ***Required***. [GeoJSON geometry object](http://geojson.org/geojson-spec.html#geometry-objects)

##### Result

Integer. The relationship geometry is successfully created if an integer is returned.

##### Example(s)

-   Create new relationship geometry for relationship id: 2

```SELECT * FROM cd_create_relationship_geometry(1,2,$anystr${"type":"Point","coordinates":[-72.9490754,40.8521095]}$anystr$);```

14

<a name="cd_delete_parcel"/>
cd\_delete\_parcel
===========================

##### Description

Delete a parcel and all existing relationships.

##### Parameter(s)

1. parcel\_id (integer) - **Required**.

##### Result

Boolean. True/False valid.

##### Example(s)
Delete parcel id 3

```  SELECT * from cd_delete_parcel(3);```

TRUE

<a name="cd_delete_parcels"/>
cd\_delete\_parcels
===========================

##### Description

Delete list of parcel\_ids and all associated relationships.

##### Parameter(s)

1. parcel\_ids (character varying) - **Required**. comma separated list of parcel_ids to delete.

##### Result

Integer array of deleted parcel ids.

##### Example(s)

```  SELECT * from cd_delete_parcels('2,139,333');```

| integer[]   |
|-------------|
| {2,139,333}   |


<a name="cd_archive_parcel"/>
cd\_archive\_parcel
===========================

##### Description

Archive a parcel and all existing relationships.

##### Parameter(s)

1. parcel\_id (integer) - **Required**.

##### Result

Boolean. True/False valid.

##### Example(s)
Archive parcel id 3

```  SELECT * from cd_archive_parcel(3);```

TRUE

<a name="cd_archive_parcels"/>
cd\_archive\_parcels
===========================

##### Description

Archive list of parcel\_ids and all existing relationships.

##### Parameter(s)

1. parcel\_ids (character varying) - **Required**. comma separated list of parcel_ids to archive.

##### Result

Integer array of archived parcel ids.

##### Example(s)

```  SELECT * from cd_archives_parcels('2,139,333');```

| integer[]   |
|-------------|
| {2,139,333} |


<a name="cd_delete_relationship"/>
cd\_delete\_relationship
===========================

##### Description

Delete a relationship.

##### Parameter(s)

1. relationship\_id (integer) - **Required**.

##### Result

Boolean. True/False valid.

##### Example(s)
Delete relationship id 13

```  SELECT * from cd_delete_relationship(13);```

TRUE

<a name="cd_delete_relationships"/>
cd\_delete\_relationships
===========================

##### Description

Delete list of relationship\_ids.

##### Parameter(s)

1. relationship\_ids (character varying) - **Required**. comma separated list of relationship_ids to delete.

##### Result

Integer array of deleted relationship ids.

##### Example(s)

```  SELECT * from cd_delete_relationships('9,19,33');```

| integer[]   |
|-------------|
| {9,19,33}   |


<a name="cd_archive_relationship"/>
cd\_archive\_relationship
===========================

##### Description

Archive a relationship.

##### Parameter(s)

1. relationship\_id (integer) - **Required**.

##### Result

Boolean. True/False valid.

##### Example(s)
Archive relationship id 3

```  SELECT * from cd_archive_relationship(3);```

TRUE

<a name="cd_archive_relationships"/>
cd\_archive\_relationships
===========================

##### Description

Archive list of relationship\_ids.

##### Parameter(s)

1. relationship\_ids (character varying) - **Required**. comma separated list of relationship_ids to archive.

##### Result

Integer array of archived relationship ids.

##### Example(s)

```  SELECT * from cd_archive_relationships('2,139,333');```

| integer[]   |
|-------------|
| {2,139,333} |


<a name="cd_validate_parcels"/>
cd\_validate\_parcels
===========================

##### Description

Validate list of parcel\_ids.

##### Parameter(s)

1. parcel\_ids (character varying) - **Required**. comma separated list of parcel_ids to validate.

##### Result

Integer array of valid ACTIVE parcel_ids.

##### Example(s)

```SELECT * FROM cd_validate_parcels('3,4,5');```

| integer[]   |
|-------------|
| {3,4,5}|


<a name="cd_validate_parcel"/>
cd\_validate\_parcel
===========================

##### Description

Validate an parcel\_id.

##### Parameter(s)

1. parcel\_id (integer) - **Required**. parcel_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM cd_validate_parcel(3);```

TRUE

<a name="cd_validate_relationships"/>
cd\_validate\_relationships
===========================

##### Description

Validate list of relationship\_ids.

##### Parameter(s)

1. relationship\_ids (character varying) - **Required**. comma separated list of relationship_ids to validate.

##### Result

Integer array of valid ACTIVE relationship_ids.

##### Example(s)

```SELECT * FROM cd_validate_relationships('3,4,5');```

| integer[]   |
|-------------|
| {3,4,5}     |

<a name="cd_validate_relationship"/>
cd\_validate\_relationship
===========================

##### Description

Validate an relationship\_id.

##### Parameter(s)

1. relationship\_id (integer) - **Required**. relationship_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM cd_validate_relationship(3);```

TRUE

<a name="cd_validate_organization"/>
cd\_validate\_organization
===========================

##### Description

Validate an organization\_id.

##### Parameter(s)

1. organization\_id (integer) - **Required**. organization_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM cd_validate_organization(3);```

TRUE

<a name="cd_validate_organizations"/>
cd\_validate\_organizations
===========================

##### Description

Validate list of organization\_ids.

##### Parameter(s)

1. organization\_ids (character varying) - **Required**. comma separated list of organization_ids to validate.

##### Result

Integer array of valid ACTIVE organization_ids.

##### Example(s)

```SELECT * FROM cd_validate_organizations('3,4,5');```

| integer[]   |
|-------------|
| {3,4,5}     |


<a name="cd_validate_project"/>
cd\_validate\_project
===========================

##### Description

Validate an project\_id.

##### Parameter(s)

1. project\_id (integer) - **Required**. project_id to validate.

##### Result

Boolean. True/False valid.

##### Example(s)

```SELECT * FROM cd_validate_project(3);```

TRUE

<a name="cd_validate_projects"/>
cd\_validate\_projects
===========================

##### Description

Validate list of project\_ids.

##### Parameter(s)

1. project\_ids (character varying) - **Required**. comma separated list of project_ids to validate.

##### Result

Integer array of valid ACTIVE project_ids.

##### Example(s)

```SELECT * FROM cd_validate_projects('3,4,5');```

| integer[]   |
|-------------|
| {3,4,5}     |


<a name="cd_import_data_json"/>
cd\_import\_data\_json
=================

##### Description

Import Formhub/ONA Form data

***Important:**** JSON string must be encapsulated inside of '$anystr$'

```var json = '$anystr$' + JsonString + '$anystr$' ;```

##### Parameter(s)

1.  json\_string (character varying) – ***Required***.

##### Result

Boolean. True if survey data is successfully inserted into DB

##### Example(s)

-   Add survey data to DB

``` SELECT * FROM cd_import_data_json ($anystr$[{
          "_notes": [],
          "applicant_name/applicant_name_first": "Makkonen",
          "_bamboo_dataset_id": "",
          "_tags": [],
          "surveyor": "katechapman",
          "_xform_id_string": "CJF-minimum-Test",
          "_geolocation": {
            "type": "Polygon",
            "coordinates": [
              [
                [
                  -68.13127398490906,
                  -16.498594502708375
                ],
                [
                  -68.13038885593414,
                  -16.4990522778716
                ],
                [
                  -68.13022255897522,
                  -16.49927344975331
                ],
                [
                  -68.1305605173111,
                  -16.499906102809422
                ],
                [
                  -68.13167631626129,
                  -16.49923744504563
                ],
                [
                  -68.13127398490906,
                  -16.498594502708375
                ]
              ]
            ]
          },
          "_duration": 27.0,
          "meta/instanceID": "uuid:6d998c3d-d712-4dbc-b041-16939500f5a7",
          "end": "2015-10-07T12:55:55.218-07",
          "date_land_possession": "2010-05-25",
          "applicant_name/applicant_name_last": "Ontario ",
          "start": "2015-10-07T12:55:28.024-07",
          "_attachments": [],
          "_status": "submitted_via_web",
          "today": "2015-10-07",
          "_uuid": "6d998c3d-d712-4dbc-b041-16939500f5a7",
          "means_of_acquire": "inheritance",
          "_submitted_by": null,
          "formhub/uuid": "5b453ab2cbec49f79193293262d68376",
          "_submission_time": "2015-10-07T19:55:46",
          "_version": "201510071848",
          "tenure_type": "common_law_freehold",
          "deviceid": "35385206286421",
          "_id": 15}
        ]$anystr$);```
        
```[ { cd_import_data_json: true } ]```

