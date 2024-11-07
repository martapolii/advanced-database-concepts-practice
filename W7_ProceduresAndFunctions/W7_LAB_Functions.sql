--Q. 6-10. Calculating the total pledge amount.

--Create a function to determine the total pledge amount for a project.
--Then use the function in an SQL statement to list all the projects project ID, project name, project pledge total amount.
--Format the pledge total to have a dollar sign showed.


--created a function which collects the needed info in its parameters, and stores it in a string format as the value of the lv_total_pledge variable 
CREATE OR REPLACE FUNCTION total_pledge_sf
(p_projID IN NUMBER, -- p = parameter 
p_proj_name IN VARCHAR,
p_pledge_amt IN NUMBER)

RETURN VARCHAR2
IS
lv_total_pledge VARCHAR2(500); -- lv = local variable 
BEGIN
lv_total_pledge := 'Project ID: ' || p_projID || ' - Project Name: ' || p_proj_name || ' - Pledge Total Amount: $' ||  TO_CHAR(p_pledge_amt, 'FM9999990.00');
RETURN lv_total_pledge;
END;

-- now need to use the function in an SQL statement 
SELECT --pr.idproj, 
    --pr.projname,                 -- if I select these 3 columns then I get a table with themm + the output from the function. we ONLY want the output from the function 
    --SUM(pl.pledgeamt) AS total_pledge,
    total_pledge_sf(pr.idproj, pr.projname, SUM(pl.pledgeamt)) AS "Total Pledge"
FROM dd_project pr 
JOIN dd_pledge pl
ON pr.idproj = pl.idproj
GROUP BY pr.idproj, pr.projname; -- aggregates pledge amounts to avoid duplicates 