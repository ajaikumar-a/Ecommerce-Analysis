/* Customer Activity Growth 2016-2018 */ 
==========================================

/* 1) Average active users per year */
-------------------------------------------

-- This query calculates the average number of active users per year based on data from the orders and customers tables.

-- Select the year column and the rounded average of total_customers column for each year from the results of the subquery "total_users".

SELECT
  year,
  ROUND(AVG(total_customers), 0) avg_active_users
FROM
 (
   -- This subquery calculates the total number of unique customers in each month of each year by joining the orders table with the customers table on the customer_id column. 
   -- It groups the results by year and month and calculates the count of unique customer IDs in each group.
   SELECT
     DATEPART(YEAR, o.order_purchase_timestamp) year,
     DATEPART(MONTH, o.order_purchase_timestamp) month,
     COUNT(DISTINCT(c.customer_unique_id)) total_customers
   FROM
     orders o
     JOIN customers c
     ON o.customer_id = c.customer_id
   GROUP BY
     DATEPART(YEAR, o.order_purchase_timestamp),
     DATEPART(MONTH, o.order_purchase_timestamp)
 ) total_users
GROUP BY
  year;


/* 2) New users per year */
------------------------------

-- This query calculates the number of new customers for each year based on the first order date in the orders table.

-- Select the year and the count of distinct customer_unique_id for each year from the results of the subquery "first_purchase".

SELECT
  DATEPART(YEAR, first_order) year,
  COUNT(DISTINCT(customer_unique_id)) new_customers
FROM
 (
   -- This subquery finds the first order date for each unique customer by joining the customers and orders tables on the customer_id column.
   -- It groups the results by customer_unique_id and calculates the minimum order_purchase_timestamp for each group.
   SELECT
     c.customer_unique_id,
     MIN(o.order_purchase_timestamp) first_order
   FROM
     customers c
     JOIN orders o
     ON c.customer_id = o.customer_id
   GROUP BY
     c.customer_unique_id
 ) first_purchase
GROUP BY
  DATEPART(YEAR, first_order);



/* 3) Customers with repeat orders */
---------------------------------------

-- This query calculates the number of customers with repeat orders for each year.

-- Select the year and the count of customer_unique_id for each year from the results of the subquery "ro".
SELECT
  year,
  COUNT(customer_unique_id) customers_with_repeat_orders
FROM
 (
   -- This subquery finds the number of orders for each unique customer and year by joining the customers and orders tables on the customer_id column.
   -- It groups the results by year and customer_unique_id and calculates the count of orders for each group.
   -- It also filters the groups by the count of orders greater than 1 to get the customers with repeat orders.
   SELECT
     DATEPART(YEAR, o.order_purchase_timestamp) year,
     c.customer_unique_id,
     COUNT(o.order_id) no_of_orders
   FROM
     customers c
      JOIN orders o
        ON c.customer_id = o.customer_id
   GROUP BY
     DATEPART(YEAR, o.order_purchase_timestamp),
     c.customer_unique_id
   HAVING
     COUNT(o.order_id) > 1
 ) ro
GROUP BY
  year;



/* 4) Average orders by customers */
--------------------------------------

-- Select the year and the average number of orders per customer for each year from the results of the subquery "repeat_orders".
SELECT
  year,
  AVG(no_of_orders) avg_orders_by_customer
FROM
(
-- This subquery finds the number of orders for each unique customer and year by joining the customers and orders tables on the customer_id column.
-- It groups the results by year and customer_unique_id and counts the number of orders for each group.
	SELECT
	  DATEPART(YEAR, o.order_purchase_timestamp) year,
	  c.customer_unique_id,
	  COUNT(o.order_id) no_of_orders
	FROM
	  customers c
	  JOIN orders o
	    ON c.customer_id = o.customer_id
	GROUP BY
	  DATEPART(YEAR, o.order_purchase_timestamp),
	  c.customer_unique_id
) repeat_orders
GROUP BY
  year;


/* Summary */
--------------

-- Creating CTEs for summarizing the above results
WITH active_users AS
  ( 
	SELECT
	  year,
	  ROUND(AVG(total_customers), 0) avg_active_users
	FROM
	  (
		SELECT
  		  DATEPART(YEAR, o.order_purchase_timestamp) year,
		  DATEPART(MONTH, o.order_purchase_timestamp) month,
		  COUNT(DISTINCT(c.customer_unique_id)) total_customers
		FROM
		  orders o 
		  JOIN customers c 
		  ON o.customer_id = c.customer_id
		GROUP BY
		  DATEPART(YEAR, o.order_purchase_timestamp),
		  DATEPART(MONTH, o.order_purchase_timestamp)
	  ) total_users
	GROUP BY
	  year
  ),
  new_users AS
  (
	SELECT
	  DATEPART(YEAR, first_order) year,
	  COUNT(DISTINCT(customer_unique_id)) new_customers
	FROM
	  (
		SELECT
		  c.customer_unique_id,
		  MIN(o.order_purchase_timestamp) first_order
		FROM
		  customers c
		  JOIN orders o
		  ON c.customer_id = o.customer_id
		GROUP BY
		  c.customer_unique_id
	  ) first_purchase
	GROUP BY 
	  DATEPART(YEAR, first_order)
	),
	repeat_orders AS
	(
		SELECT
		  year,
		  COUNT(customer_unique_id) customers_with_repeat_orders
		FROM
		  (
			SELECT
			  DATEPART(YEAR, o.order_purchase_timestamp) year,
			  c.customer_unique_id,
			  COUNT(o.order_id) no_of_orders
			FROM
			  customers c
			  JOIN orders o
			    ON c.customer_id = o.customer_id
			GROUP BY 
			  DATEPART(YEAR, o.order_purchase_timestamp),
			  c.customer_unique_id
			HAVING 
			  COUNT(o.order_id) > 1
		  ) ro
		GROUP BY
		  year
	),
	average_orders AS
	(
		SELECT
		  year,
		  AVG(no_of_orders) avg_orders_by_customer
		FROM
		  (
			SELECT
			  DATEPART(YEAR, o.order_purchase_timestamp) year,
			  c.customer_unique_id,
			  COUNT(o.order_id) no_of_orders
			FROM
			  customers c
			  JOIN orders o
			    ON c.customer_id = o.customer_id
			GROUP BY 
			  DATEPART(YEAR, o.order_purchase_timestamp),
			  c.customer_unique_id
		  ) repeat_orders
		GROUP BY
		  year
	)

SELECT
  a.year,
  a.avg_active_users,
  n.new_customers,
  r.customers_with_repeat_orders,
  av.avg_orders_by_customer
FROM
  active_users a 
  JOIN new_users n 
    ON a.year = n.year
  JOIN repeat_orders r 
    ON a.year = r.year
  JOIN average_orders av 
    ON a.year = av.year
ORDER BY
  year desc;
---------------------------------------------------------------------------------------------------------------------------------------------------


/* Product category quality analysis 2016-2018 */
===================================================

/* 1) Total revenue per year */
--------------------------------

-- Select the year and the rounded sum of revenue_per_order for each year from the subquery "rev" joined with the "orders" table.
SELECT
  DATEPART(YEAR, o.order_purchase_timestamp) year,
  ROUND(SUM(rev.revenue_per_order), 2) revenue
FROM
 (
   -- This subquery calculates the revenue_per_order for each order in the "order_items" table.
   -- It groups the results by order_id and sums the price and freight_value for each order.
   SELECT
     order_id,
     ROUND(SUM(price + freight_value), 2) revenue_per_order
   FROM
     order_items
   GROUP BY
     order_id ) rev
  JOIN orders o
   ON rev.order_id = o.order_id
WHERE
  o.order_status = 'delivered'
GROUP BY
  DATEPART(YEAR, o.order_purchase_timestamp)
ORDER BY
  DATEPART(YEAR, o.order_purchase_timestamp) DESC;


	
/* 2) Total canceled orders per year */
----------------------------------------

-- Select the year and the count of distinct order_id for each year from the canceled orders in the orders table.
SELECT
  DATEPART(YEAR, order_purchase_timestamp) year,
  COUNT(DISTINCT order_id) canceled_orders
FROM
  orders
WHERE
  order_status = 'canceled'
GROUP BY
  DATEPART(YEAR, order_purchase_timestamp)
ORDER BY
  DATEPART(YEAR, order_purchase_timestamp) DESC;



/* 3) Best selling product category by year */
-----------------------------------------------

-- Select the year, product category, and revenue for each year's highest revenue-generating product category.
SELECT
  year,
  product_category,
  revenue
FROM
 (
   -- This subquery selects the year, product category, and revenue for each product category by joining the orders, order_items, and products tables.
   -- It groups the results by year and product category, and calculates the sum of the price and freight_value columns for each order item to determine the revenue.
   -- It also uses the RANK() function to assign a ranking to each product category within each year based on the revenue, with the highest-revenue category assigned a ranking of 1.
   SELECT
     DATEPART(YEAR, o.order_purchase_timestamp) year,
     p.product_category_name product_category,
     ROUND(SUM(oi.price + oi.freight_value), 2) revenue,
     RANK() OVER (PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp) 
		   ORDER BY ROUND(SUM(oi.price + oi.freight_value), 2) DESC) AS ranking
   FROM
     products p
     JOIN order_items oi
       ON p.product_id = oi.product_id
     JOIN orders o
       ON oi.order_id = o.order_id
   GROUP BY
     DATEPART(YEAR, o.order_purchase_timestamp),
     p.product_category_name
 ) revenue_rank
WHERE
  ranking = 1 -- Select only the rows where the product category has the highest revenue ranking for each year.
ORDER BY
  year DESC; 


/* 4) Most canceled category */
--------------------------------

-- Select the year, product category, and count of canceled orders for the top-selling product category each year.
SELECT
  year,
  product_category,
  canceled_orders
FROM
 (
   -- Subquery to get the year, product category, and count of canceled orders for each product category each year
   SELECT
     DATEPART(YEAR, o.order_purchase_timestamp) year,
     p.product_category_name product_category,
     COUNT(o.order_id) canceled_orders,
     RANK() OVER (PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
                   ORDER BY COUNT(o.order_id) DESC) ranking
  FROM
    orders o
     JOIN order_items oi
       ON o.order_id = oi.order_id
     JOIN products p
       ON oi.product_id = p.product_id
  WHERE
    o.order_status = 'canceled'
  GROUP BY
    DATEPART(YEAR, order_purchase_timestamp),
    p.product_category_name
 ) cancels
WHERE
  ranking = 1 -- Only include the top-selling product category for each year
ORDER BY
  year DESC; 


/* Summary */

-- Creating CTEs for summarizing the above results
WITH revenue_per_year AS
 (
	SELECT
	  DATEPART(YEAR, o.order_purchase_timestamp) year,
	  ROUND(SUM(rev.revenue_per_order), 2) revenue
	FROM
	  (
		SELECT
		  order_id,
		  ROUND(SUM(price + freight_value), 2) revenue_per_order
		FROM 
		  order_items
		GROUP BY
		  order_id
	  ) rev
	  JOIN orders o
	    ON rev.order_id = o.order_id
	WHERE
	  o.order_status = 'delivered'
	GROUP BY
	  DATEPART(YEAR, o.order_purchase_timestamp)

 ),
 canceled_orders_per_year AS
 (
	SELECT
	  DATEPART(YEAR, order_purchase_timestamp) year,
	  COUNT(DISTINCT order_id) canceled_orders
	FROM
	  orders
	WHERE 
	  order_status = 'canceled'
	GROUP BY
	  DATEPART(YEAR, order_purchase_timestamp)
	
  ),
  best_selling_category AS
  (
	SELECT
	  year,
	  product_category,
	  revenue 
	FROM
	  (
		SELECT 
		  DATEPART(YEAR, o.order_purchase_timestamp) year,
		  p.product_category_name product_category,
		  ROUND(SUM(oi.price + oi.freight_value), 2) revenue,
		  RANK() OVER (PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
				ORDER BY ROUND(SUM(oi.price + oi.freight_value), 2) DESC) AS ranking 
		FROM
		  products p
		  JOIN order_items oi
		    ON p.product_id = oi.product_id
		  JOIN orders o 
		    ON oi.order_id = o.order_id
		GROUP BY
		  DATEPART(YEAR, o.order_purchase_timestamp),
		  p.product_category_name
	  ) revenue_rank
	WHERE
	  ranking = 1

  ),
  most_canceled_category AS 
  (
	SELECT
	  year,
	  product_category,
	  canceled_orders
	FROM 
	  (
		SELECT
		  DATEPART(YEAR, o.order_purchase_timestamp) year,
		  p.product_category_name product_category,
		  COUNT(o.order_id) canceled_orders,
		  RANK() OVER (PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
				ORDER BY COUNT(o.order_id) DESC) ranking
		FROM 
		  orders o
		  JOIN order_items oi
		    ON o.order_id = oi.order_id
		  JOIN products p
	  	    ON oi.product_id = p.product_id
		WHERE
		  o.order_status = 'canceled'
		GROUP BY
		  DATEPART(YEAR, order_purchase_timestamp),
		  p.product_category_name
	  ) cancels
	WHERE
	  ranking = 1
	
  )

SELECT
  r.year,
  r.revenue,
  c.canceled_orders,
  b.product_category best_selling_category,
  b.revenue best_selling_revenue,
  m.product_category most_canceled_category,
  m.canceled_orders most_canceled_orders
FROM
  revenue_per_year r
  JOIN canceled_orders_per_year c
    ON r.year = c.year
  JOIN best_selling_category b
    ON r.year = b.year
  JOIN most_canceled_category m
    ON r.year = m.year;



-------------------------------------------------------------------------------------------------------------------------------------


/* Payment Type Usage */
==========================

/* 1) Favorite payment type */
-------------------------------

-- Select the payment type and the count of orders for each payment type, sorted by the count of orders in descending order.
SELECT
  payment_type,
  COUNT(payment_type) no_of_usage
FROM
  order_payments
GROUP BY
  payment_type
ORDER BY
  no_of_usage DESC;


/* 2) Top favorite payment type by year */
-------------------------------------------

-- This SQL query retrieves the favorite payment type by year
-- It calculates the number of usages of each payment type and ranks them by usage count
-- It then selects the payment type with the highest usage count for each year
-- The result set includes the year, favorite payment type, and the number of times it was used
SELECT
  year,
  favorite_payment_type,
  no_of_usage
FROM
 (
   -- This subquery calculates the usage count of each payment type by year
   -- It ranks the payment types by usage count within each year
   SELECT
     DATEPART(YEAR, o.order_purchase_timestamp) year,
     op.payment_type favorite_payment_type,
     COUNT(op.payment_type) no_of_usage,
     RANK() OVER (PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
                   ORDER BY COUNT(op.payment_type) DESC) payment_ranking
   FROM
     order_payments op
      JOIN orders o
        ON op.order_id = o.order_id
   GROUP BY
     DATEPART(YEAR, o.order_purchase_timestamp),
     op.payment_type
 ) p
-- This query selects only the payment types with the highest usage count for each year
WHERE
  payment_ranking = 1;

	
 /* 3) payment usage per year */
 --------------------------------

-- This common table expression calculates the number of times each payment type was used in each year
WITH usage AS
(
  SELECT
    DATEPART(YEAR, o.order_purchase_timestamp) year,
    op.payment_type payment_type,
    COUNT(op.payment_type) no_of_usage
  FROM
    order_payments op
    JOIN orders o
      ON op.order_id = o.order_id
  GROUP BY
    DATEPART(YEAR, o.order_purchase_timestamp),
    op.payment_type
)

-- This query summarizes the usage of each payment type by year
SELECT
  payment_type,
  SUM(CASE WHEN year = 2016 THEN no_of_usage ELSE 0 END) '2016_usage',
  SUM(CASE WHEN year = 2017 THEN no_of_usage ELSE 0 END) '2017_usage',
  SUM(CASE WHEN year = 2018 THEN no_of_usage ELSE 0 END) '2018_usage'
FROM
  usage
GROUP BY
  payment_type;
  







	 




	
