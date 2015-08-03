-- Function: cd_process_form()

-- DROP FUNCTION cd_process_form();

CREATE OR REPLACE FUNCTION cd_process_form()
  RETURNS trigger AS
$BODY$
DECLARE
  parent_question_id integer;
  parent_question_type record;
  parent_question_json record;
  parent_question_name text;
  parent_question_label text;
  parent_question_children record;
  parent_group_id integer;
  parent_question_prefix text;

  child_question_id integer;
  child_question_type record;
  child_question_json record;
  child_question_name text;
  child_question_label text;
  child_question_children record;
  child_group_id integer;
  child_question_prefix text;

  grandchild_question_id integer;
  grandchild_question_type record;
  grandchild_question_json record;
  grandchild_question_name text;
  grandchild_question_label text;
  grandchild_question_children record;
  grandchild_group_id integer;
  grandchild_question_prefix text;

  greatgrandchild_question_id integer;
  greatgrandchild_question_type record;
  greatgrandchild_question_json record;
  greatgrandchild_question_name text;
  greatgrandchild_question_label text;
  greatgrandchild_question_children record;
  greatgrandchild_group_id integer;
  greatgrandchild_question_prefix text;

  section_id integer;
  question_section_id integer;
  section_name text;
  raw_form_id integer;
  survey_id integer;
  survey_project_id int;
BEGIN
  raw_form_id := NEW.id;

 IF (NEW.json IS NOT NULL) THEN
    RAISE NOTICE 'Form has json to process.';
    EXECUTE 'INSERT INTO survey (id_string) VALUES ((SELECT value::text FROM json_each_text((select json from raw_form where id = ' || raw_form_id || ')) WHERE key = ''id_string'')) RETURNING id' INTO survey_id;
    EXECUTE 'UPDATE survey SET name = (SELECT value::text FROM json_each_text((select json from raw_form where id = ' || raw_form_id || ')) WHERE key = ''name'') WHERE id = ' || survey_id;
    EXECUTE 'UPDATE survey SET label = (SELECT value::text FROM json_each_text((select json from raw_form where id = ' || raw_form_id || ')) WHERE key = ''title'') WHERE id = ' || survey_id;
    RAISE NOTICE 'Created Survey';
 END IF;

  -- loop through the parent questions (top level)
  FOR parent_question_json IN (SELECT json_array_elements(value) as json FROM json_each((select json from raw_form where id = raw_form_id)) WHERE key = 'children') LOOP
    -- get the type
    SELECT INTO parent_question_type id,name,has_options,time_created FROM type WHERE lower(name) = (SELECT lower(value) FROM json_each_text(parent_question_json.json) WHERE key = 'type');

    RAISE NOTICE 'Made it to parent type %', parent_question_type;

    -- based on the type process the parent question
    IF parent_question_type IS NOT NULL THEN
      -- collect the name and label from the parent question
      SELECT INTO parent_question_name value::text FROM json_each_text(parent_question_json.json) WHERE key = 'name';
      SELECT INTO parent_question_label value::text FROM json_each_text(parent_question_json.json) WHERE key = 'label';
      parent_question_prefix := lower(left(parent_question_name, position('.' in parent_question_name)-1));
      -- parent question type
      CASE (parent_question_type.name)
         -- parent section headings or closing statements
         WHEN ('note') THEN
         RAISE NOTICE 'Made it Note';

         -- update survey project id

         SELECT INTO survey_project_id project_id FROM survey WHERE id = survey_id;
         IF survey_project_id IS NULL AND parent_question_name = 'project_id' THEN
            RAISE NOTICE 'Found project id %', parent_question_name;


            UPDATE survey SET project_id = (SELECT value::int FROM json_each_text(parent_question_json.json) WHERE key = 'label');
         END IF;

        /******************************************************************************
	   SECTIONS
	******************************************************************************/
	   EXECUTE 'INSERT INTO section (survey_id, name, label) VALUES ('||survey_id||','||quote_literal(parent_question_name)||','||quote_literal(parent_question_label)||') RETURNING id' INTO section_id;
	   section_name := parent_question_name;
	   RAISE NOTICE '-----> NEW SECTION: %', parent_question_label || ' (' || section_id || ')';
         -- parent group
         WHEN 'repeat','group' THEN
         /******************************************************************************
           CHILDREN QUESTIONS
         ******************************************************************************/
           IF parent_question_name IS NOT NULL AND parent_question_label IS NOT NULL THEN
             EXECUTE 'INSERT INTO "q_group" (survey_id,name, label) VALUES ('||survey_id||','||quote_literal(parent_question_name)||','||quote_literal(parent_question_label)||') RETURNING id' INTO parent_group_id;
	     RAISE NOTICE '----------> NEW GROUP: %', parent_question_label || ' (' || parent_group_id || ')';
	     -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(parent_question_prefix)  ORDER BY id DESC LIMIT 1;
	     -- if the current section name matches the group prefix (right of period '.') then it belongs to the section
             -- IF question_section_id IS NOT NULL THEN
               -- EXECUTE 'UPDATE "q_group" SET section_id = ' || question_section_id || ' WHERE id = ' || parent_group_id;
             -- END IF;
             IF section_id IS NOT NULL THEN
		EXECUTE 'UPDATE "q_group" SET section_id = ' || section_id || ' WHERE id = ' || parent_group_id;
	     END IF;
	     SELECT INTO parent_question_children json_array_elements(value) as json FROM json_each(parent_question_json.json) WHERE key = 'children';
	     IF parent_question_children IS NOT NULL THEN
	       -- loop through the child questions
	       FOR child_question_json IN (SELECT json_array_elements(value) as json FROM json_each(parent_question_json.json) WHERE key = 'children') LOOP
	          -- get the type
		  SELECT INTO child_question_type * FROM type WHERE lower(name) = (SELECT lower(value) FROM json_each_text(child_question_json.json) WHERE key = 'type');
		  -- based on the type process the child question
		  IF child_question_type IS NOT NULL THEN
		    -- collect the name and label from the child question
		    SELECT INTO child_question_name value::text FROM json_each_text(child_question_json.json) WHERE key = 'name';
		    SELECT INTO child_question_label value::text FROM json_each_text(child_question_json.json) WHERE key = 'label';
		    child_question_prefix := lower(left(child_question_name, position('.' in child_question_name)-1));
		    -- parent question type
		    CASE (child_question_type.name)
		      -- child group
		      WHEN 'repeat','group' THEN
		      /******************************************************************************
			GRAND-CHILDREN QUESTIONS
		      ******************************************************************************/
		        -- the child question must have a name and label to be recorded ('meta' types do not get recorded)
		        IF child_question_name IS NOT NULL AND child_question_label IS NOT NULL THEN
		          EXECUTE 'INSERT INTO "q_group" (survey_id,parent_id, name, label) VALUES ('||survey_id||','||parent_group_id||','||quote_literal(child_question_name)||','||quote_literal(child_question_label)||') RETURNING id' INTO child_group_id;
			  RAISE NOTICE '---------------> NEW GROUP: %', child_question_label || ' (' || child_group_id || ')';
			  -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(child_question_prefix)  ORDER BY id DESC LIMIT 1;
			  -- if the current section name matches the group prefix (right of period '.') then it belongs to the section
			  -- IF question_section_id IS NOT NULL THEN
			  --  EXECUTE 'UPDATE "q_group" SET section_id = ' || question_section_id || ' WHERE id = ' || child_group_id;
			  -- END IF;
			  IF section_id IS NOT NULL THEN
			    EXECUTE 'UPDATE "q_group" SET section_id = ' || section_id || ' WHERE id = ' || child_group_id;
			  END IF;
			  SELECT INTO child_question_children json_array_elements(value) as json FROM json_each(child_question_json.json) WHERE key = 'children';
			  IF child_question_children IS NOT NULL THEN
			    -- loop through the grandchild questions
			    FOR grandchild_question_json IN (SELECT json_array_elements(value) as json FROM json_each(child_question_json.json) WHERE key = 'children') LOOP
			      -- get the type
			      SELECT INTO grandchild_question_type * FROM type WHERE lower(name) = (SELECT lower(value) FROM json_each_text(grandchild_question_json.json) WHERE key = 'type');
			      -- based on the type process the grandchild question
			      IF grandchild_question_type IS NOT NULL THEN
			        -- collect the name and label from the grandchild question
			        SELECT INTO grandchild_question_name value::text FROM json_each_text(grandchild_question_json.json) WHERE key = 'name';
			        SELECT INTO grandchild_question_label value::text FROM json_each_text(grandchild_question_json.json) WHERE key = 'label';
			        grandchild_question_prefix := lower(left(grandchild_question_name, position('.' in grandchild_question_name)-1));
			        -- grandchild question type
			        CASE (grandchild_question_type.name)
				  -- grandchild group
				   WHEN 'repeat','group' THEN
				    /******************************************************************************
					GREAT-GRAND-CHILDREN QUESTIONS
				    ******************************************************************************/
				    -- the grandchild question must have a name and label to be recorded ('meta' types do not get recorded)
				   IF grandchild_question_name IS NOT NULL AND grandchild_question_label IS NOT NULL THEN
				     EXECUTE 'INSERT INTO "q_group" (survey_id,parent_id, name, label) VALUES ('||survey_id||','||child_group_id||','||quote_literal(grandchild_question_name)||','||quote_literal(grandchild_question_label)||') RETURNING id' INTO grandchild_group_id;
				     RAISE NOTICE '--------------------> NEW GROUP: %', grandchild_question_label || ' (' || grandchild_group_id || ')';
				     -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(grandchild_question_prefix)  ORDER BY id DESC LIMIT 1;
				      -- if the current section name matches the group prefix (right of period '.') then it belongs to the section
				     -- IF question_section_id IS NOT NULL THEN
				       -- EXECUTE 'UPDATE "q_group" SET section_id = ' || question_section_id || ' WHERE id = ' || grandchild_group_id;
				     -- END IF;
				     IF section_id IS NOT NULL THEN
				       EXECUTE 'UPDATE "q_group" SET section_id = ' || section_id || ' WHERE id = ' || grandchild_group_id;
				     END IF;
				     SELECT INTO grandchild_question_children json_array_elements(value) as json FROM json_each(grandchild_question_json.json) WHERE key = 'children';
				     IF grandchild_question_children IS NOT NULL THEN
				       -- loop through the greatgrandchild questions
				       FOR greatgrandchild_question_json IN (SELECT json_array_elements(value) as json FROM json_each(grandchild_question_json.json) WHERE key = 'children') LOOP
				         -- get the type
				         SELECT INTO greatgrandchild_question_type * FROM type WHERE lower(name) = (SELECT lower(value) FROM json_each_text(greatgrandchild_question_json.json) WHERE key = 'type');
				         -- based on the type process the grandchild question
			                 IF greatgrandchild_question_type IS NOT NULL THEN
			                   -- collect the name and label from the greatgrandchild question
					   SELECT INTO greatgrandchild_question_name value::text FROM json_each_text(greatgrandchild_question_json.json) WHERE key = 'name';
					   SELECT INTO greatgrandchild_question_label value::text FROM json_each_text(greatgrandchild_question_json.json) WHERE key = 'label';
					   greatgrandchild_question_prefix := lower(left(greatgrandchild_question_name, position('.' in greatgrandchild_question_name)-1));
			                 END IF;
			                 -- greatgrandchild question type

					 CASE (greatgrandchild_question_type.name)
					   -- greatgrandchild questions with options
					   WHEN 'select all that apply','selection one' THEN
					     EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||greatgrandchild_question_type.id||','||quote_literal(greatgrandchild_question_name)||','||quote_literal(greatgrandchild_question_label)||') RETURNING id' INTO greatgrandchild_question_id;
					     IF section_id IS NOT NULL THEN
					       EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || greatgrandchild_question_id;
					     END IF;
					     -- this question belongs to the child group of the parent group
				             IF grandchild_group_id IS NOT NULL THEN
				               EXECUTE 'UPDATE question SET group_id = ' || grandchild_group_id || ' WHERE id = ' || greatgrandchild_question_id;
				             END IF;
					     RAISE NOTICE '-------------------------> QUESTION: %', greatgrandchild_question_label || ' (' || greatgrandchild_question_type.name || ')';
					   ELSE
					     EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||greatgrandchild_question_type.id||','||quote_literal(greatgrandchild_question_name)||','||quote_literal(greatgrandchild_question_label)||') RETURNING id' INTO greatgrandchild_question_id;
					     IF section_id IS NOT NULL THEN
					       EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || greatgrandchild_question_id;
					     END IF;
					     -- this question belongs to the child group of the parent group
				             IF grandchild_group_id IS NOT NULL THEN
				               EXECUTE 'UPDATE question SET group_id = ' || grandchild_group_id || ' WHERE id = ' || greatgrandchild_question_id;
				             END IF;
					     RAISE NOTICE '-------------------------> QUESTION: %', greatgrandchild_question_label || ' (' || greatgrandchild_question_type.name || ')';
					 END CASE;
			               END LOOP;
			             END IF;
				   END IF;
				   WHEN 'select all that apply','select one' THEN
				    /******************************************************************************
				     GRAND-CHILD QUESTIONS (WITH OPTIONS)
				   ******************************************************************************/
				     EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||grandchild_question_type.id||','||quote_literal(grandchild_question_name)||','||quote_literal(grandchild_question_label)||') RETURNING id' INTO grandchild_question_id;
				     -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(grandchild_question_prefix)  ORDER BY id DESC LIMIT 1;
				     -- if the current section name matches the question prefix (right of period '.') then it belongs to the section
				     -- IF question_section_id IS NOT NULL THEN
				     --  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || grandchild_question_id;
				     -- END IF;
				     IF section_id IS NOT NULL THEN
				       EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || grandchild_question_id;
				     END IF;
				     -- this question belongs to the child group of the parent group
				     IF child_group_id IS NOT NULL THEN
				       EXECUTE 'UPDATE question SET group_id = ' || child_group_id || ' WHERE id = ' || grandchild_question_id;
				     END IF;
				     RAISE NOTICE '--------------------> GRAND-CHILD QUESTION: %', grandchild_question_label || ' (' || grandchild_question_type.name || ')';
				     SELECT INTO grandchild_question_children json_array_elements(value) as json FROM json_each(grandchild_question_json.json) WHERE key = 'children';
				     IF grandchild_question_children IS NOT NULL THEN
				       -- loop through the parent childrend to collect the options
				       FOR greatgrandchild_question_json IN (SELECT json_array_elements(value) as json FROM json_each(grandchild_question_children.json) WHERE key = 'children') LOOP
					 -- collect the name and label from the grandchild question
					 SELECT INTO greatgrandchild_question_name value::text FROM json_each_text(greatgrandchild_question_json.json) WHERE key = 'name';
					 SELECT INTO greatgrandchild_question_label value::text FROM json_each_text(greatgrandchild_question_json.json) WHERE key = 'label';
					 -- create the option record
					 EXECUTE 'INSERT INTO option (question_id, name, label) VALUES (' || grandchild_question_id ||','|| quote_literal(greatgrandchild_question_name) ||','|| quote_literal(greatgrandchild_question_label) || ')';
				       END LOOP;
				     END IF;
				   ELSE
				   /******************************************************************************
				     GRAND-CHILD QUESTIONS
				   ******************************************************************************/
				     EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||grandchild_question_type.id||','||quote_literal(grandchild_question_name)||','||quote_literal(grandchild_question_label)||') RETURNING id' INTO grandchild_question_id;
				     -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(grandchild_question_prefix)  ORDER BY id DESC LIMIT 1;
				     -- if the current section name matches the question prefix (right of period '.') then it belongs to the section
				     -- IF question_section_id IS NOT NULL THEN
				     --  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || grandchild_question_id;
				     -- END IF;
				     IF section_id IS NOT NULL THEN
				       EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || grandchild_question_id;
				     END IF;
				      -- this question belongs to the child group of the parent group
				     IF child_group_id IS NOT NULL THEN
				       EXECUTE 'UPDATE question SET group_id = ' || child_group_id || ' WHERE id = ' || grandchild_question_id;
				     END IF;
				     RAISE NOTICE '--------------------> GRAND-CHILD QUESTION: %', grandchild_question_label || ' (' || grandchild_question_type.name || ')';
			        END CASE;
			      END IF;
			    END LOOP;
			  END IF;
		        END IF;
		      WHEN 'select all that apply','select one' THEN
		       /******************************************************************************
			CHILD QUESTIONS (WITH OPTIONS)
		      ******************************************************************************/
		        EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||child_question_type.id||','||quote_literal(child_question_name)||','||quote_literal(child_question_label)||') RETURNING id' INTO child_question_id;
			-- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(child_question_prefix)  ORDER BY id DESC LIMIT 1;
			-- if the current section name matches the question prefix (right of period '.') then it belongs to the section
			-- IF question_section_id IS NOT NULL THEN
			--  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || child_question_id;
			-- END IF;
			IF section_id IS NOT NULL THEN
			  EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || child_question_id;
			END IF;
			-- this question belongs to the parent group
			IF parent_group_id IS NOT NULL THEN
			  EXECUTE 'UPDATE question SET group_id = ' || parent_group_id || ' WHERE id = ' || child_question_id;
			END IF;
		        RAISE NOTICE '---------------> CHILD QUESTION: %', child_question_label || ' (' || child_question_type.name || ')';
		        SELECT INTO child_question_children json_array_elements(value) as json FROM json_each(child_question_json.json) WHERE key = 'children';
			IF child_question_children IS NOT NULL THEN
			  -- loop through the parent childrend to collect the options
			  FOR grandchild_question_json IN (SELECT json_array_elements(value) as json FROM json_each(child_question_json.json) WHERE key = 'children') LOOP
			    -- collect the name and label from the grandchild question
			    SELECT INTO grandchild_question_name value::text FROM json_each_text(grandchild_question_json.json) WHERE key = 'name';
			    SELECT INTO grandchild_question_label value::text FROM json_each_text(grandchild_question_json.json) WHERE key = 'label';
			    -- create the option record
			    EXECUTE 'INSERT INTO option (question_id, name, label) VALUES (' || child_question_id ||','|| quote_literal(grandchild_question_name) ||','|| quote_literal(grandchild_question_label) || ')';
			  END LOOP;
			END IF;
		      ELSE
		      /******************************************************************************
			CHILD QUESTIONS
		      ******************************************************************************/
		        EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||child_question_type.id||','||quote_literal(child_question_name)||','||quote_literal(child_question_label)||') RETURNING id' INTO child_question_id;
			-- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(child_question_prefix)  ORDER BY id DESC LIMIT 1;
			-- if the current section name matches the question prefix (right of period '.') then it belongs to the section
			-- IF question_section_id IS NOT NULL THEN
			--  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || child_question_id;
			-- END IF;
			IF section_id IS NOT NULL THEN
			  EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || child_question_id;
			END IF;
			-- this question belongs to the parent group
			IF parent_group_id IS NOT NULL THEN
			  EXECUTE 'UPDATE question SET group_id = ' || parent_group_id || ' WHERE id = ' || child_question_id;
			END IF;
		        RAISE NOTICE '---------------> CHILD QUESTION: %', child_question_label || ' (' || child_question_type.name || ')';
		    END CASE;
	         END IF;
	       END LOOP;  -- child questions (loop)
	     END IF;
	   END IF;
         WHEN 'select all that apply','select one' THEN
         /******************************************************************************
	   PARENT QUESTIONS (WITH OPTIONS)
	 ******************************************************************************/
           EXECUTE 'INSERT INTO question (survey_id, type_id, name, label) VALUES ('||survey_id||','||parent_question_type.id||','||quote_literal(parent_question_name)||','||quote_literal(parent_question_label)||') RETURNING id' INTO parent_question_id;
           -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(parent_question_prefix)  ORDER BY id DESC LIMIT 1;
           -- if the current section name matches the question prefix (right of period '.') then it belongs to the section
           -- IF question_section_id IS NOT NULL THEN
           --  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || parent_question_id;
           -- END IF;
           IF section_id IS NOT NULL THEN
             EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || parent_question_id;
           END IF;
           RAISE NOTICE '-----> PARENT QUESTION: %', parent_question_label;
           SELECT INTO parent_question_children json_array_elements(value) as json FROM json_each(parent_question_json.json) WHERE key = 'children';
	   IF parent_question_children IS NOT NULL THEN
	     -- loop through the parent childrend to collect the options
	     FOR child_question_json IN (SELECT json_array_elements(value) as json FROM json_each(parent_question_json.json) WHERE key = 'children') LOOP
	       -- collect the name and label from the child question
	       SELECT INTO child_question_name value::text FROM json_each_text(child_question_json.json) WHERE key = 'name';
	       SELECT INTO child_question_label value::text FROM json_each_text(child_question_json.json) WHERE key = 'label';
               -- create the option record
               EXECUTE 'INSERT INTO option (question_id, name, label) VALUES (' || parent_question_id ||','|| quote_literal(child_question_name) ||','|| quote_literal(child_question_label) || ')';
             END LOOP;
           END IF;
         ELSE
         /******************************************************************************
	   PARENT QUESTIONS
	 ******************************************************************************/
           INSERT INTO question (survey_id, type_id, name, label) VALUES (survey_id,parent_question_type.id,quote_literal(parent_question_name),quote_literal(parent_question_label)) RETURNING id INTO parent_question_id;
           -- SELECT INTO question_section_id id FROM (SELECT id, CASE WHEN position('.' in name) > 0 THEN lower(left(name, position('.' in name)-1)) ELSE name END as sectionname FROM section) sections WHERE lower(sectionname) = lower(parent_question_prefix)  ORDER BY id DESC LIMIT 1;
           -- if the current section name matches the question prefix (right of period '.') then it belongs to the section
           -- IF question_section_id IS NOT NULL THEN
           --  EXECUTE 'UPDATE question SET section_id = ' || question_section_id || ' WHERE id = ' || parent_question_id;
           -- END IF;
           IF section_id IS NOT NULL THEN
             EXECUTE 'UPDATE question SET section_id = ' || section_id || ' WHERE id = ' || parent_question_id;
           END IF;
           RAISE NOTICE '-----> PARENT QUESTION: %', parent_question_label;
      END CASE;
    END IF;
   END LOOP; -- parent questions (loop)

  RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION cd_process_form()
  OWNER TO postgres;

DROP TRIGGER IF EXISTS cd_process_form ON raw_form;
CREATE TRIGGER cd_process_form AFTER INSERT ON raw_form
    FOR EACH ROW EXECUTE PROCEDURE cd_process_form();