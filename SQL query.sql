USE [E-commerce] -- E-commerce is the database containing the tables.

/* Customer Activity Growth 2016-2018 */ 

-- 1) Average active users per year
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
	year;


-- 2) New users per year 

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
	DATEPART(YEAR, first_order);



-- 3) Customers with repeat orders
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
	year;



-- 4) Average orders by customers
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
	year;


-- Summary
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

-- Total revenue per year
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
ORDER BY
	DATEPART(YEAR, o.order_purchase_timestamp) DESC;


	
-- Total canceled orders per year
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
	DATEPART(YEAR, order_purchase_timestamp) DESC



-- Best selling product category by year
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
		RANK() OVER
				(
				  PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
				  ORDER BY ROUND(SUM(oi.price + oi.freight_value), 2) DESC
				) AS ranking 
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
ORDER BY
	year DESC


-- Most canceled category
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
		RANK() OVER
				(
				  PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
				  ORDER BY COUNT(o.order_id) DESC
				) ranking
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
ORDER BY
	year DESC


-- Summary
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
			RANK() OVER
					(
					  PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
					  ORDER BY ROUND(SUM(oi.price + oi.freight_value), 2) DESC
					) AS ranking 
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
			RANK() OVER
					(
					  PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
					  ORDER BY COUNT(o.order_id) DESC
					) ranking
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
		ON r.year = m.year



-------------------------------------------------------------------------------------------------------------------------------------


/* Payment Type Usage */

-- Favorite payment type
SELECT
	payment_type,
	COUNT(payment_type) no_of_usage
FROM
	order_payments
GROUP BY
	payment_type
ORDER BY
	no_of_usage DESC

-- Top favorite payment type by year
SELECT
	year,
	favorite_payment_type,
	no_of_usage
FROM
  (
	SELECT
		DATEPART(YEAR, o.order_purchase_timestamp) year,
		op.payment_type favorite_payment_type,
		COUNT(op.payment_type) no_of_usage,
		RANK() OVER
				(
				  PARTITION BY DATEPART(YEAR, o.order_purchase_timestamp)
				  ORDER BY COUNT(op.payment_type) DESC 
				) payment_ranking
	FROM
		order_payments op
		JOIN orders o
		  ON op.order_id = o.order_id
	GROUP BY
		DATEPART(YEAR, o.order_purchase_timestamp),
		op.payment_type 
  ) p
WHERE
	payment_ranking = 1

	
 -- payment usage per year

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

  
SELECT
	payment_type,
	SUM(CASE WHEN year = 2016 THEN no_of_usage ELSE 0 END) '2016_usage',
	SUM(CASE WHEN year = 2017 THEN no_of_usage ELSE 0 END) '2017_usage',
	SUM(CASE WHEN year = 2018 THEN no_of_usage ELSE 0 END)'2018_usage'
FROM
	usage
GROUP BY
	payment_type
  







	 




	
