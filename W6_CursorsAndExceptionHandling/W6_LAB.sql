
-- code DOES NOT DISPLAY QUERY RESULTS. executes successfully despite using a basket id value that does not exist 
-- UPDATE: fixed by enabling serveroutput with the following command:
SET SERVEROUTPUT ON;

/*
Week 6 - Lab Exercise

1.	In the Brewbean�s application, a customer can ask to check whether all items in his or her basket are in stock. 
    Now you are asked to create a PL/SQL block that uses an explicit cursor to retrieve all items in the basket and determine whether 
    all items are in stock by comparing the item quantity with the product stock amount. If all items are in stock, display the message 
    �All items in stock!� onscreen. If not, display the message �Some items are not in stock!� onscreen. 
    The basket number is provided with an initialized variable.  
    
    1)	Modify your solution by using parameterized the cursor
    2)	Modify your solution by adding exception to enforce the business logic  
*/

-- notes:
-- use explicit cursor to retrieve all items in the basket
-- determine if in stock by comparing item quantity with product stock amount
-- make an exception handler: 
    -- if in stock "All items instock!"
    -- if not: "Some items are not in stock!"
-- basket number provided w initialized variable 

-- bb_product table has stock
-- bb_basketitem has quantity, idbasketitem, idbasket, idproduct

DECLARE
    CURSOR cur_stock(p_basket NUMBER) IS 
        SELECT bi.idbasket, bi.idbasketitem, idproduct, bi.quantity, pr.stock
            FROM bb_basketitem bi
            JOIN bb_product pr USING(idproduct)
            WHERE bi.idBasket = p_basket;
            
    -- declare record type and variable to hold fetched data
    TYPE type_basket IS RECORD (
        basketID bb_basketitem.idbasket%TYPE,
        item bb_basketitem.idbasketitem%TYPE,
        product bb_basketitem.idproduct%TYPE,
        quantity bb_basketitem.quantity%TYPE,
        stock bb_product.stock%TYPE);
        
    -- declare record variable of type type_basket
    rec_basket type_basket; 
    -- need a variable to hold true/false value for in_stock
    in_stock BOOLEAN := TRUE;
      -- declare a variable to track if any items are found
    no_items_found BOOLEAN := TRUE;
    -- need to declare an exception
    basket_not_valid EXCEPTION;
    basket_num NUMBER := 6; --initialize basket number ** PUT BASKET # HERE**
    
BEGIN
  OPEN cur_stock(basket_num); --open cursor with parameter
    LOOP
        FETCH cur_stock INTO rec_basket;
        EXIT WHEN cur_stock%NOTFOUND;
        
        -- if atleast one item is found:
        no_items_found := FALSE;
        
        -- check condition:
        IF rec_basket.quantity > rec_basket.stock 
            THEN in_stock := FALSE; 
            DBMS_OUTPUT.PUT_LINE('Some items are not in stock.');
        END IF;
    END LOOP;
 
    -- check if no items found
        IF no_items_found THEN
            RAISE basket_not_valid;
        END IF;
        
    -- check if in stock
        IF in_stock THEN 
            DBMS_OUTPUT.PUT_LINE('All items in stock!');
        END IF;
  CLOSE cur_stock;
  
-- exception handler for user-defined exception
EXCEPTION 
    WHEN basket_not_valid THEN 
        DBMS_OUTPUT.PUT_LINE('Empty basket or basket does not exist.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An unexpected error has occurred.');
END;
