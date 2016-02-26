/******************************************************************

 Function: cd_process_attachments()

 Parses _attachment metadata from raw_data json and creates
 resources based on attachment resource_type.

******************************************************************/
DROP FUNCTION cd_process_attachments(integer,integer,integer,integer,integer);
 
CREATE OR REPLACE FUNCTION cd_process_attachments(proj_id int, pty_id int, pcel_id int, rel_id int, field_id int)
RETURNS BOOLEAN AS $$
DECLARE
    data_json json;
    survey record;
    attachments json;
    attachment json;
    element record;
    party_type text;
    resource_type text;
    filename character varying;
    url character varying;
    data_field_data_id int;
    data_project_id int;
    survey_host character varying;
BEGIN
    
    FOR survey IN (SELECT * FROM json_array_elements((select json from raw_data WHERE id = field_id AND project_id = proj_id))) LOOP
        SELECT INTO attachments value::json FROM (SELECT * FROM json_each_text(survey.value) WHERE key = '_attachments') AS att;
        IF attachments IS NOT NULL THEN
            FOR attachment IN (SELECT * FROM json_array_elements((attachments))) LOOP
                RAISE LOG 'Attachment is %', attachment;
                FOR element IN (SELECT * FROM json_each_text(attachment)) LOOP
                    CASE (element.key)
                        WHEN 'resource_type' THEN
                            resource_type := element.value;
                        WHEN 'resource_file_name' THEN
                            filename := element.value;
                        WHEN 'download_url' THEN
                            url := element.value;
                        WHEN 'survey_host' THEN
			    survey_host := element.value;
                        ELSE 
                    END CASE;
                END LOOP;
                -- add survey host to url
                url := 'http://' || survey_host || url;
                RAISE LOG '%, %, %, %, %', proj_id, resource_type, pty_id, url, filename;
                    
                    CASE (resource_type)
                        WHEN 'party' THEN
                            PERFORM cd_create_resource(proj_id, resource_type, pty_id, url, '', filename);
                        WHEN 'parcel' THEN
                            PERFORM cd_create_resource(proj_id, resource_type, pcel_id, url, '', filename);
                        WHEN 'relationship' THEN
                            PERFORM cd_create_resource(proj_id, resource_type, rel_id, url, '', filename);
                        ELSE
                    END CASE;
            END LOOP;
        ELSE
            RAISE LOG 'no attachments found';
        END IF;
    END LOOP;
    RETURN TRUE;
END;	
$$ LANGUAGE plpgsql VOLATILE;



