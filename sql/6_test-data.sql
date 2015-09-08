-- Create fake org and project until API endpoint is built

INSERT INTO organization (title) VALUES ('HFH');
INSERT INTO project (organization_id, title) VALUES ((SELECT id from organization where title = 'HFH'), 'Bolivia');