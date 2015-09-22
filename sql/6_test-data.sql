-- Create fake org and project until API is wrapped in CKAN API

SELECT * FROM cd_create_organization('demo-organization','Demo Organization',null);
SELECT * FROM cd_create_project((Select id from organization where ckan_id = 'demo-organization'),'demo-project ','Friday Night');