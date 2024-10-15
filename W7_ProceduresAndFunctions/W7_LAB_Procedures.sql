--Q - Create a procedure to retrieve project information for a specific project based on a project ID.
--    The procedure should have two parameters: 
--                - one to accept a project ID value 
--                - another to return all data for the specified project.
--                       Use a record variable to hold what the procedure returns 

-- A:
-- all info needed is in table: DD_PROJECT
-- need to create a procedire, input: project ID, output: a record variable (custom data type essentially) storing all the info from the table 

CREATE OR REPLACE
PROCEDURE project_info_sp
    (p_projectID IN NUMBER)
    IS
    --initialize record variable data type:
    TYPE type_project_data IS RECORD (
        ID dd_project.idproj%TYPE,
        name dd_project.projname%TYPE,
        start_date dd_project.projstartdate%TYPE,
        end_date dd_project.projenddate%TYPE,
        fund_goal dd_project.projfundgoal%TYPE,
        coordinator dd_project.projcoord%TYPE);
        
    -- declare record variable of type type_project_data
       rec_project type_project_data; 
BEGIN
    SELECT * -- select all info from dd_project table and insert it into the record variable for the project id number specified
        INTO rec_project
        FROM dd_project
        WHERE idproj = p_projectID;
    -- output all the data by calling on the record variable, then '.' and property name as we defined when making the record variable above
    DBMS_OUTPUT.PUT_LINE('Project ID: ' || rec_project.ID);
    DBMS_OUTPUT.PUT_LINE('Project Name: ' || rec_project.name);
    DBMS_OUTPUT.PUT_LINE('Project Start Date: ' || rec_project.start_date);
    DBMS_OUTPUT.PUT_LINE('Project End Date: ' || rec_project.end_date);
    DBMS_OUTPUT.PUT_LINE('Project Fund Goal: ' || rec_project.fund_goal);
    DBMS_OUTPUT.PUT_LINE('Project Coordinator: ' || rec_project.coordinator);
END;

DECLARE
    project_number NUMBER := ('500'); -- substitute project number here 
BEGIN
     project_info_sp(project_number); -- call the stored procedure many times on any project number
    --project_info_sp('500'); -- OR just simply input the number here as a parameter without storing it in a variable first
END;
