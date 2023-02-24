/* Data cleaning */ 
====================

-- The SQL queries used for conducting data cleaning on the different tables are given below.


/* Table: "orders" */
======================

-- Checking for null records
-----------------------------
SELECT
  *
FROM
  orders
WHERE
  order_id IS NULL OR
  customer_id IS NULL OR
  order_status IS NULL OR
  order_purchase_timestamp IS NULL OR
  order_approved_at IS NULL OR
  order_delivered_carrier_date IS NULL OR
  order_delivered_customer_date IS NULL OR
  order_estimated_delivery_date IS NULL

-- Removing null records
--------------------------
DELETE FROM 
  orders
WHERE 
  order_id IS NULL OR
  customer_id IS NULL OR
  order_status IS NULL OR
  order_purchase_timestamp IS NULL OR
  order_approved_at IS NULL OR
  order_delivered_carrier_date IS NULL OR
  order_delivered_customer_date IS NULL OR
  order_estimated_delivery_date IS NULL;

-- Checking for duplicate records
------------------------------------
SELECT
  order_id, 
  customer_id,
  order_status, 
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date,
  COUNT(*) total_records
FROM	
  orders
GROUP BY
  order_id, 
  customer_id,
  order_status, 
  order_purchase_timestamp,
  order_approved_at,
  order_delivered_carrier_date,
  order_delivered_customer_date,
  order_estimated_delivery_date
HAVING 
  COUNT(*) > 1;

-- Removing duplicate records
-------------------------------
DELETE FROM 
  orders
WHERE 
  order_id IN (
    -- Select all columns from the 'orders' table and group them by their values
    SELECT
        order_id,
        customer_id,
        order_status, 
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        COUNT(*) total_records -- Count the number of occurrences for each group

    FROM 
      orders
    -- Group the records by their values
    GROUP BY
        order_id,
        customer_id,
        order_status, 
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date
    -- Select only the groups where there are duplicates
    HAVING 
      COUNT(*) > 1
)
-- Use ROW_NUMBER() function to assign a unique number to each row within its group
-- This ensures that only one row for each group is kept in the 'orders' table
AND (ROW_NUMBER() OVER (
    PARTITION BY 
		order_id, 
		customer_id,
		order_status, 
		order_purchase_timestamp,
		order_approved_at,
		order_delivered_carrier_date,
		order_delivered_customer_date,
		order_estimated_delivery_date -- Define the grouping columns
    ORDER BY (SELECT NULL) 
-- Order the rows within each group by an arbitrary constant value
-- Since the SELECT statement in the ORDER BY clause returns a constant NULL value for each row, the rows within each group are not sorted in any specific order
) > 1);

		
-- Changing the date columns into yyyy-mm-dd format
----------------------------------------------------
UPDATE 
  orders 
SET order_purchase_timestamp = CONVERT(date, CONVERT(datetime, order_purchase_timestamp, 1), 112), 
    order_approved_at = CONVERT(date, CONVERT(datetime, order_approved_at, 1), 112),
    order_delivered_carrier_date = CONVERT(date, CONVERT(datetime, order_delivered_carrier_date, 1), 112),
    order_delivered_customer_date = CONVERT(date, CONVERT(datetime, order_delivered_customer_date, 1), 112),
    order_estimated_delivery_date = CONVERT(date, CONVERT(datetime, order_estimated_delivery_date, 1), 112);

**********************************************************************************************************************************************************************************************************************************************************************************************************************************	

/* Table: "order_items" */
============================

-- Checking for null records
------------------------------

SELECT
  *
FROM
  order_items
WHERE
  order_id IS NULL OR
  order_item_id IS NULL OR
  product_id IS NULL OR
  seller_id IS NULL OR
  shipping_limit_date IS NULL OR
  price IS NULL OR
  freight_value IS NULL;


-- Checking for duplicate records
-----------------------------------

SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value,
  COUNT(*) total_records
FROM
  order_items
GROUP BY
  order_id,
  order_item_id,
  product_id,
  seller_id,
  shipping_limit_date,
  price,
  freight_value
HAVING 
  COUNT(*) > 1;


-- Rounding the 'price' and 'freight_value' columns to two decimal places
---------------------------------------------------------------------------

UPDATE 
  order_items
SET price = ROUND(price, 2),
    freight_value = ROUND(freight_value, 2)

**********************************************************************************************************************************************************************************************************************************************************************************************************************************

/* Table: "customers" */
=========================

-- Checking for null records
------------------------------

SELECT
  *
FROM
  customers
WHERE
  customer_id IS NULL OR
  customer_city IS NULL OR
  customer_state IS NULL OR
  customer_unique_id IS NULL OR
  customer_zip_code_prefix IS NULL;


-- Checking for duplicate records
-----------------------------------

SELECT
  customer_id, 
  customer_city, 
  customer_state, 
  customer_unique_id, 
  customer_zip_code_prefix, 
  COUNT(*) total_records
FROM	
  customers
GROUP BY
  customer_id, customer_city, customer_state, customer_unique_id, customer_zip_code_prefix
HAVING 
  COUNT(*) > 1;

**********************************************************************************************************************************************************************************************************************************************************************************************************************************

/* Table: "geolocation" */
==========================

-- Checking for null values
----------------------------

SELECT
  *
FROM	
  geolocation
WHERE
  geolocation_zip_code_prefix IS NULL OR
  geolocation_lat IS NULL OR
  geolocation_lng IS NULL OR
  geolocation_city IS NULL OR
  geolocation_state IS NULL


-- Checking for duplicate records
-----------------------------------

SELECT
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state,
  COUNT(*) total_records
FROM
  geolocation
GROUP BY
  geolocation_zip_code_prefix,
  geolocation_lat,
  geolocation_lng,
  geolocation_city,
  geolocation_state
HAVING 
  COUNT(*) > 1;


-- Removing duplicate records
------------------------------

DELETE FROM 
  geolocation
WHERE EXISTS (
	SELECT 
	  geolocation_zip_code_prefix
	FROM 
	(
	  SELECT 
	    geolocation_zip_code_prefix
	  FROM 
	    geolocation
          GROUP BY 
	    geolocation_zip_code_prefix, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state
	  HAVING 
	    COUNT(*) > 1
	) AS d
	WHERE 
	  d.geolocation_zip_code_prefix = geolocation.geolocation_zip_code_prefix
	  AND (ROW_NUMBER() OVER (PARTITION BY geolocation_zip_code_prefix ORDER BY (SELECT NULL))) > 1
);


-- Removing the 'geolocation_lat' and 'geolocation_lng' columns
----------------------------------------------------------------

ALTER TABLE 
  geolocation
DROP COLUMN 
  geolocation_lat, geolocation_lng;

**********************************************************************************************************************************************************************************************************************************************************************************************************************************

/* Table: "payments" */
========================

-- Checking for null records
-----------------------------

SELECT
  *
FROM
  payments
WHERE
  order_id IS NULL OR
  payment_sequential IS NULL OR
  payment_installments IS NULL OR
  payment_type IS NULL OR
  payment_value IS NULL;


-- Checking for duplicate records
----------------------------------

SELECT
  order_id, 
  payment_sequential, 
  payment_type, 
  payment_installments, 
  payment_value, 
  COUNT(*) total_records
FROM
  payments
GROUP BY
  order_id, 
  payment_sequential, 
  payment_type, 
  payment_installments, 
  payment_value
HAVING 
  COUNT(*) > 1;


-- Rounding the values in the 'payment_value' column into two decimal places
-----------------------------------------------------------------------------

UPDATE 
  payments
SET
  payment_value = ROUND(payment_value, 2);



/* Table: "products" */ 
========================

-- Removing unnecessary columns
---------------------------------

ALTER TABLE 
  products
DROP COLUMN 
  product_name_length, 
  product_description_length, 
  product_photos_qty, 
  product_weight_g, 
  product_length_m, 
  product_height_cm,
  product_width_cm


-- Checking for null records
-----------------------------

SELECT 
  *
FROM 
  products
WHERE
  product_id IS NULL OR
  product_category_name IS NULL


-- Removing null records
--------------------------

DELETE FROM 
  products
WHERE product_id IN 
	(
	  SELECT 
	    product_id,
	    product_category_name
	  FROM 
            products
	  WHERE
	    product_id IS NULL OR
	    product_category_name IS NULL
	);


-- Checking for duplicate records
----------------------------------

SELECT
  product_id, 
  product_category_name,
  COUNT(*) total_records
FROM	
  products
GROUP BY
  product_id,
  product_category_name
HAVING 
  COUNT(*) > 1;

******************************************************************************************************************************************************************************************************************
