--CHAPTER 7: PL/SQL PACKAGES

-- Run next statement to enable DBMS_OUTPUT.PUT_LINE function 
SET SERVEROUTPUT ON;


-- CREATING PACKAGES 
-- a "package specification":
CREATE OR REPLACE PACKAGE ordering_pkg 
  IS 
  pv_total_num NUMBER(3,2); -- pv = package variable 
  PROCEDURE order_total_pp -- contains a procedure
     (p_bsktid IN NUMBER,
     p_cnt OUT NUMBER,
     p_sub OUT NUMBER,
     p_ship OUT NUMBER,
     p_total OUT NUMBER);
  FUNCTION ship_calc_pf -- and a function 
    (p_qty IN NUMBER)
    RETURN NUMBER;
END;

-- order doesnt matter unless referencing something else in a declaration

-- INVOKING A PACKAGE CONSTRUCT
    -- use an anonymous block & reference package name and prpgram unit name 
    
    DECLARE
        lv_bask_num bb_basketitem.idbasket%TYPE := 12;
        lv_cnt_num NUMBER(3);
        lv_sub_num NUMBER(8,2);
        lv_ship_num NUMBER(8,2);
        lv_total_num NUMBER(8,2);
    BEGIN
        ordering_pkg.order_total_pp(  --** INVOKED HERE
            lv_bask_num, lv_cnt_num, lv_sub_num,
            lv_ship_num, lv_total_num
        );
    
        DBMS_OUTPUT.PUT_LINE(lv_cnt_num);
        DBMS_OUTPUT.PUT_LINE(lv_sub_num);
        DBMS_OUTPUT.PUT_LINE(lv_ship_num);
        DBMS_OUTPUT.PUT_LINE(lv_total_num);
    END;
    
    -- verify results against database:
    SELECT SUM(quantity), SUM(quantity*price)
        FROM bb_basketitem
        WHERE idbasket = 12;

    -- can invoke anything in the package specification from outside the package:
    DECLARE
    lv_ship_num NUMBER(8,2);
    BEGIN
        lv_ship_num := ordering_pkg.ship_calc_pf(7); -- package name.program unit name 
        DBMS_OUTPUT.PUT_LINE(lv_ship_num);
    END;

-- PACKAGE SCOPE
    -- If you try to call a function/procedure that is not in the specification, it wont work bc its private!
    
-- GLOBAL CONSTRUCTS IN PACKAGES + PERSISTENCE DURING USER SESSION

-- PACKAGE SPECIFICATIONS WITH NO BODY
    -- can be used to hold values 
    -- ex: conversion factors
        CREATE OR REPLACE PACKAGE metric_pkg
    IS
        cup_to_liter CONSTANT NUMBER := 0.24;
        pint_to_liter CONSTANT NUMBER := 0.47;
        qrt_to_liter CONSTANT NUMBER := 0.95;
    END;

-- IMPROVING EFFICIENCY
    -- to display elapsed execution time:
    SET TIMING ON;
    
    -- an example package:
        CREATE OR REPLACE PACKAGE budget_pkg
    IS
        CURSOR pcur_sales IS
            SELECT p.idProduct, p.price, p.type, SUM(bi.quantity) qty
            FROM bb_product p, bb_basketitem bi, bb_basket b
            WHERE p.idProduct = bi.idProduct
              AND b.idBasket = bi.idBasket
              AND b.orderplaced = 1
            GROUP BY p.idProduct, p.price, p.type;
    
        PROCEDURE project_sales_pp
            (p_pcte IN OUT NUMBER,
             p_pctc IN OUT NUMBER,
             p_incr OUT NUMBER);
    END;
    
    CREATE OR REPLACE PACKAGE BODY budget_pkg
    IS
        PROCEDURE project_sales_pp
            (p_pcte IN OUT NUMBER,
             p_pctc IN OUT NUMBER,
             p_incr OUT NUMBER)
        IS
            equip NUMBER := 0;
            coff NUMBER := 0;
        BEGIN
            FOR rec_sales IN pcur_sales LOOP
                IF rec_sales.type = 'E' THEN
                    equip := equip + ((rec_sales.price * p_pcte) * rec_sales.qty);
                ELSIF rec_sales.type = 'C' THEN
                    coff := coff + ((rec_sales.price * p_pctc) * rec_sales.qty);
                END IF;
            END LOOP;
    
            p_incr := equip + coff;
        END;
    END;
    -- call it (elapsed time: .078
    DECLARE
        lv_pcte_num NUMBER(3,2) := 0.03;
        lv_pctc_num NUMBER(3,2) := 0.07;
        lv_incr_num NUMBER(6,2);
    BEGIN
        budget_pkg.project_sales_pp(lv_pcte_num, lv_pctc_num, lv_incr_num);
        DBMS_OUTPUT.PUT_LINE(lv_incr_num);
    END;
    -- now it should be faster bc query already cached (elapsed time: .061)
    DECLARE
        lv_pcte_num NUMBER(3,2) := 0.05;
        lv_pctc_num NUMBER(3,2) := 0.10;
        lv_incr_num NUMBER(6,2);
    BEGIN
        budget_pkg.project_sales_pp(lv_pcte_num, lv_pctc_num, lv_incr_num);
        DBMS_OUTPUT.PUT_LINE(lv_incr_num);
    END;

-- FORWARD DECLARATIONS
    -- important when not every unit is referenced in specification, but you need to
        -- specify the order so that dependent units are called properly in sequence
    CREATE OR REPLACE PACKAGE BODY ordering_pkg IS
    FUNCTION ship_calc_pf -- add this statement in the body 
        (p_qty IN NUMBER)
        RETURN NUMBER;
        
-- ONE TIME ONLY PROCEDURES
    -- run only once when packaged called 
    -- modify above provedure to include:
    CREATE OR REPLACE PACKAGE ordering_pkg
    IS
        pv_bonus_num NUMBER(3,2);
        pv_total_num NUMBER(3,2) := 0;
        PROCEDURE order_total_pp
            (p_bsktid IN bb_basketitem.idbasket%TYPE,
             p_cnt OUT NUMBER,
             p_sub OUT NUMBER,
             p_ship OUT NUMBER,
             p_total OUT NUMBER);
    END;  

    CREATE OR REPLACE PACKAGE BODY ordering_pkg
    IS
        FUNCTION ship_calc_pf
            (p_qty IN NUMBER)
            RETURN NUMBER;
    
        PROCEDURE order_total_pp
            (p_bsktid IN bb_basketitem.idbasket%TYPE,
             p_cnt OUT NUMBER,
             p_sub OUT NUMBER,
             p_ship OUT NUMBER,
             p_total OUT NUMBER)
        IS
        BEGIN
            SELECT SUM(quantity), SUM(quantity * price)
            INTO p_cnt, p_sub
            FROM bb_basketitem
            WHERE idbasket = p_bsktid;
    
            p_sub := p_sub + (p_sub * pv_bonus_num);
            p_ship := ship_calc_pf(p_cnt);
            p_total := NVL(p_sub, 0) + NVL(p_ship, 0);
        END order_total_pp;
    
        FUNCTION ship_calc_pf
            (p_qty IN NUMBER)
            RETURN NUMBER
        IS
            lv_ship_num NUMBER(5,2);
        BEGIN
            IF p_qty > 10 THEN
                lv_ship_num := 11.00;
            ELSIF p_qty > 5 THEN
                lv_ship_num := 8.00;
            ELSE
                lv_ship_num := 5.00;
            END IF;
        RETURN lv_ship_num;
        END ship_calc_pf;
    
        BEGIN
            SELECT amount -- ** ONE TIME ONLY PROCEDURE
            INTO pv_bonus_num
            FROM bb_promo
            WHERE idPromo = 'B';
        END;
        
    -- test query:
    SELECT *
        FROM bb_promo;

    -- anonymous function to check results:
     DECLARE
        lv_bask_num bb_basketitem.idbasket%TYPE := 12;
        lv_cnt_num NUMBER(3);
        lv_sub_num NUMBER(8,2);
        lv_ship_num NUMBER(8,2);
        lv_total_num NUMBER(8,2);
    BEGIN
        ordering_pkg.order_total_pp(lv_bask_num, lv_cnt_num, lv_sub_num, lv_ship_num, lv_total_num);
    
        DBMS_OUTPUT.PUT_LINE(lv_cnt_num);
        DBMS_OUTPUT.PUT_LINE(lv_sub_num);
        DBMS_OUTPUT.PUT_LINE(lv_ship_num);
        DBMS_OUTPUT.PUT_LINE(lv_total_num);
    END;


-- OVERLOADING PROGRAM UNITS IN PACKAGES
    -- can overlaod procedures that have the same function but want them to be able
    -- to accept different data types
    -- example:
    CREATE OR REPLACE PACKAGE product_info_pkg IS
    PROCEDURE prod_search_pp
        (p_id IN bb_product.idproduct%TYPE, -- SAME but diff data family
         p_sale OUT bb_product.saleprice%TYPE,
         p_price OUT bb_product.price%TYPE);

    PROCEDURE prod_search_pp
        (p_id IN bb_product.productname%TYPE, -- SAME but diff data family
         p_sale OUT bb_product.saleprice%TYPE,
         p_price OUT bb_product.price%TYPE);
    END;

    CREATE OR REPLACE PACKAGE BODY product_info_pkg IS
        PROCEDURE prod_search_pp
            (p_id IN bb_product.idproduct%TYPE,
             p_sale OUT bb_product.saleprice%TYPE,
             p_price OUT bb_product.price%TYPE)
        IS
        BEGIN
            SELECT saleprice, price
            INTO p_sale, p_price
            FROM bb_product
            WHERE idproduct = p_id;
        END;
    
        PROCEDURE prod_search_pp
            (p_id IN bb_product.productname%TYPE,
             p_sale OUT bb_product.saleprice%TYPE,
             p_price OUT bb_product.price%TYPE)
        IS
        BEGIN
            SELECT saleprice, price
            INTO p_sale, p_price
            FROM bb_product
            WHERE productname = p_id;
        END;
    END;
    
    -- call it with product it:
        DECLARE
            lv_id_num bb_product.idproduct%TYPE := 6;
            lv_sale_num bb_product.saleprice%TYPE;
            lv_price_num bb_product.price%TYPE;
        BEGIN
            product_info_pkg.prod_search_pp(lv_id_num, lv_sale_num, lv_price_num);
        
            DBMS_OUTPUT.PUT_LINE(lv_sale_num);
            DBMS_OUTPUT.PUT_LINE(lv_price_num);
        END;
        
    -- call it with product name:
        DECLARE
            lv_id_num bb_product.productname%TYPE := 'Guatamala';
            lv_sale_num bb_product.saleprice%TYPE;
            lv_price_num bb_product.price%TYPE;
        BEGIN
            product_info_pkg.prod_search_pp(lv_id_num, lv_sale_num, lv_price_num);
        
            DBMS_OUTPUT.PUT_LINE(lv_sale_num);
            DBMS_OUTPUT.PUT_LINE(lv_price_num);
        END;
    -- BOTH work!
    
-- PURITY LEVELS
    -- To check for errors at compile time rather than run time, bc onyl package specification is checked
    -- setting purity level for a specific function:
            CREATE OR REPLACE PACKAGE pack_purity_pkg IS
            FUNCTION tax_calc_pf
                (p_amt IN NUMBER)
                RETURN NUMBER;
        
            PRAGMA RESTRICT_REFERENCES(tax_calc_pf, WNDS, WNPS); --** THIS STATEMENT = PURITY LEVEL
        END;

    -- can set a DEFAULT for all functions in a package specification 
    PRAGMA RESTRICT_REFERENCES(DEFAULT, WNDS, WNPS); -- "DEFAULT"

-- USING A REF CURSOR PARAMETER IN PACKAGES 
            CREATE OR REPLACE PACKAGE demo_pkg
        AS
            TYPE genCur IS REF CURSOR;
            PROCEDURE return_set
                (p_id IN NUMBER,
                 p_theCursor IN OUT genCur);
        END;
        /
        
        CREATE OR REPLACE PACKAGE BODY demo_pkg
        AS
            PROCEDURE return_set
                (p_id IN NUMBER,
                 p_theCursor IN OUT genCur)
            IS
            BEGIN
                OPEN p_theCursor FOR SELECT * FROM bb_basketitem
                WHERE idbasket = p_id;
            END;
        END;
        /
        
        DECLARE
            bask_cur demo_pkg.genCur;
            rec_bask bb_basketitem%ROWTYPE;
        BEGIN
            demo_pkg.return_set(3, bask_cur);
        
            LOOP
                FETCH bask_cur INTO rec_bask;
                EXIT WHEN bask_cur%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE(rec_bask.idproduct);
            END LOOP;
        END;


-- GRANTING EXECUTE PRIVILEGES 
  -- default = craetor of packaged units right (definer rights)
  -- or can specify invokers (users) rights:
        CREATE OR REPLACE PACKAGE pack_purity_pkg
        AUTHID CURRENT_USER IS -- THIS LINE
            FUNCTION tax_calc_pf
                (p_amt IN NUMBER)
                RETURN NUMBER;
        END;

-- DATA DICTIONARY INFORMATION
    -- USER_SOURCE = source code 
    SELECT text
        FROM user_source
        WHERE name = 'PRODUCT_INFO_PKG';

    -- USER_OBJECTS = what packages exist on system
    SELECT object_name, object_type, status
        FROM user_objects
        WHERE object_type LIKE 'PACKAGE%';


-- DELETING PACKAGES 
    -- DROP command
        -- drop specification + body:
        DROP PACKAGE package_name;
        -- drop JUST body: 
        DROP PACKAGE BODY package_name;


