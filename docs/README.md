Cadasta Database Function Reference
===============================


##### Contents

[cd\_create\_parcel](#cd_create_parcel)

[cd\_create\_party](#cd_create_party)

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
* digitized
* recreational_gps
* survey_grade_gps
2.  ckan\_user\_id (integer) – ***Required***. The id associated with the specific CKAN user.
3.  area (numeric) – Optional. The size of the parcel.
4.  geom\_type (character varying) – ***Required***. The Geometry Type
Options:
* Point
* Polygon
* Line
5. geometry - ***Required if*** geom_type = 'Polygon' or 'Line'
5.  lat (numeric) – ***Required if*** geom\_type = 'Point'. Point Latittude
6.  lng (numeric) – ***Required if*** geom\_type = 'Point'. Point Longitude
7.  land\_use (ENUM) - Optional. Type of parcel real estate
Options:
* Commercial
* Residential
8.  gov\_pin (character varying) - Optional. 
9.  history\_description (characer varying) - Optional. A description of the parcels history

##### Result

Integer. The parcel is sucessfully created if an integer is returned. If nothing is returned, the parcel
has not been created.

##### Example(s)

-   Add new parcel of geomtry type Point and a lat/lng of (7.670367, -122.387855):

```SELECT INTO data_parcel_id * FROM cd_create_parcel ('survey_grade_gps',11,null,'Point',null,47.92883,-122.132131,null,null,'new description');```
7


<a name="cd_create_party"/>
cd\_create\_party
=================

##### Description

Create a new party

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


<a name="cd_import_data_json"/>
cd\_import\_data\_json
=================

##### Description

Import Forhum/ONA Fielddata from Ona endpoint: ```/api/v1/data/:form_id?format=json```

***Important:**** JSON string must be encapsulated inside of '$$' 

```var json = '$$' + JsonString + '$$' ;```

##### Parameter(s)

1.  field\_data\_id (integer) - ***Required***. The id of the field_data form
2.  json\_string (character varying) – ***Required***.

##### Result

Boolean. True if survey data is succesffuly inserted into DB

##### Example(s)

-   Add survey data to DB

```SELECT * FROM cd_import_data_json(5,$anystr$[{"_notes":[],"applicant_spouse_name/applicant_name_last":"Henderson","plot_address/plot_address_street":"50th ave SE","deviceid":"enketo.org:rRFxqMTT3EzpjWv6","applicant_name/applicant_name_first":"Daniel","_bamboo_dataset_id":"","_tags":[],"plot_description":"House","applicant_name/applicant_name_postfix":"jr","surveyor":"katechapman","_xform_id_string":"Basic-survey-prototype7","meta/instanceID":"uuid:a4e9fdc9-ec53-42fc-81b6-90b52ba152b2","_duration":143,"plot_number":14316,"applicant_name/geo_location":"47.867583 -122.164306 0 0","end":"2015-08-11T11:01:16.000-07:00","date_land_possession":"2015-01-04","applicant_phone_alt":"no phonenumber property in enketo","applicant_dob":"2008-01-08","applicant_name/applicant_name_last":"Banderson","start":"2015-08-11T10:58:53.000-07:00","_attachments":[],"applicant_name/applicant_name_middle":"Nathan","_status":"submitted_via_web","today":"2015-08-11","plot_address/plot_address_city":"Snohomish","plot_address/plot_address_number”:”62112”,”seller_name/seller_name_first":"Geno","applicant_marital_status":"married","_uuid":"a4e9fdc9-ec53-42fc-81b6-90b52ba152b2","applicant_phone":"no phonenumber property in enketo","means_of_acquire":"inheritance","applicant_spouse_name/applicant_name_middle":"N","_submitted_by":"nhallahan","applicant_name/applicant_name_prefix":"dr","seller_address/seller_address_city":"New Jersey","applicant_spouse_name/applicant_name_prefix":"mrs","seller_name/seller_name_last":"Smith","formhub/uuid":"d427376135c742c995a94a9d18df6614","seller_name/seller_name_postfix":"sr","applicant_spouse_name/applicant_name_first”:”Alessandra”,”_submission_time":"2015-08-11T18:01:13","seller_name/seller_name_prefix":"dr","_version":"201507162126","_geolocation":[47.867583,-122.164306],"seller_address/seller_address_street":"Sucker Drive","seller_address/seller_address_number":"2998","proprietorship":"common_law_freehold","_id":3094351},{"_notes":[],"plot_address/plot_address_street":"Thorndyke Ave W","loan_group/loan_officer/loan_officer_name_last":"Martin","loan":"yes","applicant_name/applicant_name_first":"Sarah","applicant_marital_status":"separated","_tags":[],"plot_description":"Condo","applicant_name/applicant_name_postfix":"sr","surveyor":"danielbaah","loan_group/loan_bank_name":"JP Morgan Chase","meta/instanceID":"uuid:a4156b1c-f46e-4680-9447-66843be162d5","_duration":251,"applicant_name/applicant_name_last":"Bindman","applicant_name/geo_location":"47.670367 -122.387855 0 0","end":"2015-07-16T14:31:16.000-07:00","date_land_possession":"2015-04-28","applicant_phone_alt":"no phonenumber property in enketo","applicant_dob":"2015-06-10","loan_group/loan_officer/loan_officer_name_postfix":"sr","plot_number":2501,"start":"2015-07-16T14:27:05.000-07:00","_attachments":[],"_status":"submitted_via_web","today":"2015-07-16","deviceid":"enketo.org:rRFxqMTT3EzpjWv6","plot_address/plot_address_number":"2501","_xform_id_string":"Basic-survey-prototype7","loan_group/loan_officer/loan_officer_name_prefix":"mr","loan_group/loan_officer/loan_officer_name_first":"Steve","_bamboo_dataset_id":"","_uuid":"a4156b1c-f46e-4680-9447-66843be162d5","applicant_phone":"no phonenumber property in enketo","means_of_acquire":"lease","_submitted_by":"nhallahan","applicant_name/applicant_name_prefix":"dr","seller_name/seller_name_last":"Sam","formhub/uuid":"d427376135c742c995a94a9d18df6614","seller_name/seller_name_first":"Michael","loan_group/loan_bank_branch":"Chase Bank","_submission_time":"2015-07-16T21:31:18","seller_name/seller_name_prefix":"mr","_version":"201507162126","_geolocation":[47.670367,-122.387855],"plot_address/plot_address_city":"Seattle","proprietorship":"allodial","_id":2892616}]$anystr$);```

```[ { cd_import_data_json: true } ]```

