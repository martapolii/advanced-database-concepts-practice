-- Run next statement to enable DBMS_OUTPUT.PUT_LINE function 
SET SERVEROUTPUT ON;

--Week 7 - Stored Procedures
--- program units - blocks of code that serve a function
--    - diff types: Stored, Application, Package, Database trigger, Application trigger
--    
--- procedures = named program units (blocks of code you can name and store in the database)  
--    - reusable, carry out a certain function 
--    - are created with formal parameters (only name and data type, not size)
--    - are called on with active parameters (add size) 
--    - parameters have 3 modes: IN, OUT, IN OUT 
--    
--Create procedure Syntax:
--CREATE [OR REPLACE] PROCEDURE 
--    <procedure name>
--        [(parameter1_name[mode] <data type>,
--        (parameter2_name[mode] <data type>,...)]
--    IS | AS
--      <declaration section>
--    BEGIN
--        <executable section>
--        EXCEPTION
--        <exception handlers>
--    END;
--    [] = optional


-------------------------------------------------------------------------------
--- Creating a procedure
CREATE OR REPLACE -- REPLACE incase procedure already exists; considered good practice to include 
PROCEDURE SHIP_COST_SP
        (p_qty IN NUMBER, -- formal parameters 
        p_ship OUT NUMBER)
    AS
    BEGIN
        IF p_qty > 10 THEN
            p_ship := 11.00;
        ELSIF p_qty > 5 THEN
            p_ship := 8.00;
        ELSE 
            p_ship := 5.00;
        END IF;
    END;
-------------------------------------------------------------------------------
-- Executing/Testing the procedure:
DECLARE
    lv_ship_num NUMBER(6,2); -- holds value from OUT parameter
BEGIN
    SHIP_COST_SP(7, lv_ship_num);
    DBMS_OUTPUT.PUT_LINE('Ship Cost = ' || lv_ship_num);
END;           
-- can also use Named Association Method:
DECLARE
    lv_ship_num NUMBER(6,2); -- holds value from OUT parameter
BEGIN
    SHIP_COST_SP(p_ship => lv_ship_num,
                 p_qty => 7);
    DBMS_OUTPUT.PUT_LINE('Ship Cost = ' || lv_ship_num);
END;    
-------------------------------------------------------------------------------
-- IN OUT parameters 
    -- same parameter used for input and output
    -- ex: take a phone number as input, format it, output same parameter 
CREATE OR REPLACE PROCEDURE phone_fmt_sp
    (p_phone IN OUT VARCHAR2)
    IS
BEGIN
    p_phone := '(' || SUBSTR(p_phone,1,3) || ')' || --first 3 digits in brackets
                      SUBSTR(p_phone,4,3) || '-' || -- add a dash between digits 3 & 4
                      SUBSTR(p_phone,7,4); -- list rest of digits 
END;

DECLARE 
    pn VARCHAR2(20) := '1234569999';
BEGIN
    phone_fmt_sp(pn);
        DBMS_OUTPUT.PUT_LINE('Phone number = ' || pn);
END;

-------------------------------------------------------------------------------
-- Nested Procedures 
CREATE OR REPLACE PROCEDURE order_total_sp
    (p_bsktid IN bb_basketitem.idbasket%TYPE,
    p_cnt OUT NUMBER,
    p_sub OUT NUMBER,
    p_ship OUT NUMBER,
    p_total OUT NUMBER)
  IS
BEGIN
 DBMS_OUTPUT.PUT_LINE('order total proc called');
 SELECT SUM(quantity), SUM(quantity*price)
    INTO p_cnt, p_sub
    FROM BB_BASKETITEM
    WHERE idbasket = p_bsktid;
  ship_cost_sp(p_cnt, p_ship); -- calling the procedure we made earlier
  p_total := NVL(p_sub,0) + NVL(p_ship,0);
  DBMS_OUTPUT.PUT_LINE('order total proc ended');
END ORDER_TOTAL_SP; 

-------------------------------------------------------------------------------
-- DESCRIBE command
    -- lists all inputs/outputs, names and data types 
DESCRIBE order_total_sp;

-------------------------------------------------------------------------------
-- Debugging with DBMS_OUTPUT
    -- can use DBMS_OUTPUT.PUT_LINE(values concatenated) to display values during execution and make sure they are correct 
    -- output will show logic
-------------------------------------------------------------------------------
-- Subprograms: a unit defined within another program unit
    -- declared in DECLARE section 
    -- can only be referenced by containing program unit 

-------------------------------------------------------------------------------
-- Variable Scope 
    -- inner blocks can use variables from outer blocks but not vice versa
DECLARE 
    lv_one VARCHAR2(20) := '*OUTER BLOCK 1';
    lv_two VARCHAR(20) := 'OUTER BLOCK 2';
BEGIN
    DECLARE
        lv_one VARCHAR2(20) := '****INNER BLOCK 1';
        lv_three VARCHAR(20) := '****INNER BLOCK 2';   
    BEGIN
        DBMS_OUTPUT.PUT_LINE('lv_one : ' || lv_one);
        DBMS_OUTPUT.PUT_LINE('lv_two : ' || lv_two);
        DBMS_OUTPUT.PUT_LINE('lv_three : ' || lv_three); -- these 3 statements wont throw errors bc inner block can access its own + outer blocks variables
    END;
    DBMS_OUTPUT.PUT_LINE('lv_one : ' || lv_one);
    DBMS_OUTPUT.PUT_LINE('lv_two : ' || lv_two);
    DBMS_OUTPUT.PUT_LINE('lv_three : ' || lv_three); -- this line will throw an error bc lv_three is declared in inner block, outer block does not have access
END;

-------------------------------------------------------------------------------
-- Exception handling flow
    -- starts with execution handler of block exception was raised, moves outwards until appropriate exception handler found

-------------------------------------------------------------------------------
-- Transaction Control Scope and Autonomous Transaction 
    -- COMMIT and ROLLBACK will affect ALL DML queries unless your procdure is autonomous
CREATE OR REPLACE 
PROCEDURE tc_test_sp2 IS
    PRAGMA AUTONOMOUS_TRANSACTION; -- PRAGMA = passes info to compiler rather than getting transformed into an execution
BEGIN
    INSERT INTO bb_test1
    VALUES(2);
    COMMIT;
END; 

-------------------------------------------------------------------------------
-- RAISE_APPLICATION_ERROR
    -- can raise errors on purpose (like exception handling)
    -- Stops procedure and returns control to the calling program
    -- calling program receives error number and message, can manipulate it, display it to the customer 
CREATE OR REPLACE PROCEDURE stock_ck_sp
(p_qty IN NUMBER, 
 p_prod IN NUMBER) 
IS 
 lv_stock_num bb_product.idProduct%TYPE; 
BEGIN 
  SELECT stock 
  INTO lv_stock_num 
  FROM bb_product 
  WHERE idProduct = p_prod; 
  IF p_qty > lv_stock_num THEN 
    RAISE_APPLICATION_ERROR(-20000, 'Not enough in stock. ' || 
                            'Request = ' || p_qty || ' / Stock level = ' || lv_stock_num); 
  END IF; 
EXCEPTION 
  WHEN NO_DATA_FOUND THEN 
    DBMS_OUTPUT.PUT_LINE('No Stock found.'); 
END; 

DECLARE 
    qty NUMBER := 10;
    stock NUMBER := 2;
BEGIN
    stock_ck_sp(qty,stock);
    DBMS_OUTPUT.PUT_LINE('Stock available: ' || stock || '. Quantity requested: ' || qty );
END;
    
-------------------------------------------------------------------------------
-- Remove a Procedure 
DROP PROCEDURE order_total_sp;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    