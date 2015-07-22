Cadasta Database Function Reference
===============================


##### Contents

[cd\_create\_parcel](#cd_create_parcel)

[cd\_create\_person](#cd_create_person)

[cd\_import\_form\_json](#cd_import_form_json)

[cd\_import\_data\_json](#cd_import_data_json)

* * * * *

<a name="cd_create_parcel"/>
cd\_create\_parcel
=================

##### Description

Create a new parcel and parcel history.

##### Parameter(s)

1.  spatial\_source (character varying) – ***Required***.
Options:
1. spatial_source
2. digitized
3. recreational_gps
4. survey_grade_gps
2.  ckan\_user\_id (integer) – ***Required***. The id associated with the specific CKAN user.
3.  area (numeric) – Optional. The size of the parcel.
4.  geom\_type (character varying) – ***Required***. The Geometry Type
Options:
1. Point
2. Polygon
3. Line
5.  lat (numeric) – Required if geom\_type = 'Point'. Point Latittude
6.  lng (numeric) – Required if geom\_type = 'Point'. Point Longitude
7.  land\_use (ENUM) - Optional. Type of parcel real estate
Options:
1. Commercial
2. Residential
8.  gov\_pin (character varying) - Optional. 
9.  history\_description (characer varying) - Optional. A description of the parcels history

##### Result

Integer. The parcel is sucessfully created if an integer is returned. If nothing is returned, the parcel
has not been created.

##### Example(s)

-   Add new parcel of geomtry type Point and a lat/lng of (7.670367, -122.387855) (classification\_id:769):

```SELECT * FROM cd_create_parcel ('survey_grade_gps',4,null,'point',null,7.670367,-122.387855,null,null,'new description');```


7


<a name="cd_create_person"/>
cd\_create\_person
=================

##### Description

Create a new person

##### Parameter(s)

1.  first\_name (character varying) – ***Required***.
2.  last\_name (character varying) – ***Required***.

##### Result

Integer. The person is sucessfully created if an integer is returned. If nothing is returned, the person
has not been created.

##### Example(s)

-   Create new person Sarah Beatrice

```SELECT * FROM cd_create_person ('Sarah','Beatrice');```


3

<a name="cd_import_form_json"/>
cd\_import\_form\_json
=================

##### Description

Import Forhum/ONA Survey Form data from Ona endpoint: ```/api/v1/forms/:form_id/form.json.```

***Important:**** JSON string must be encapsulated inside of '$$' 

```var json = '$$' + JsonString + '$$' ;```

##### Parameter(s)

1.  json\_string (character varying) – ***Required***.

##### Result

Boolean. True if survey is succesffuly inserted into DB

##### Example(s)

-   Add new survey form to DB

```SELECT * FROM cd_import_form_json($${"name": "Basic-survey-prototype7", "title": "Basic Cadasta Survey Prototype 7", "sms_keyword": "Basic-survey-prototype7", "default_language": "default", "version": "201507162126", "id_string": "Basic-survey-prototype7", "type": "survey", "name": "meta"}$$)```


T

<a name="cd_import_data_json"/>
cd\_import\_data\_json
=================

##### Description

Import Forhum/ONA Survey Form data from Ona endpoint: ```/api/v1/data/:form_id?format=json```

***Important:**** JSON string must be encapsulated inside of '$$' 

```var json = '$$' + JsonString + '$$' ;```

##### Parameter(s)

1.  json\_string (character varying) – ***Required***.

##### Result

Boolean. True if survey data is succesffuly inserted into DB

##### Example(s)

-   Add survey data to DB

```SELECT * FROM cd_import_data_json($$ [{"_notes": [],  "means_of_acquire": "lease", "_submitted_by": "nhallahan", "applicant_name/applicant_name_prefix": "dr", "seller_name/seller_name_last": "Sam", "formhub/uuid": "d427376135c742c995a94a9d18df6614", "seller_name/seller_name_first": "Michael", "loan_group/loan_bank_branch": "Chase Bank", "_submission_time": "2015-07-16T21:31:18", "seller_name/seller_name_prefix": "mr", "_version": "201507162126", "_geolocation": [47.670367, -122.387855], "proprietorship": "allodial", "_id": 2892616}]$$);```

T

