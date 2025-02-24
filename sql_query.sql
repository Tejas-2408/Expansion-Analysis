-- Report and Analysis

/*
Q.1 Coffee Consumers Count
How many people in each city are estimated to consume coffee, 
given that 25% of the population does?
*/

SELECT 
city_name, (0.25*population) AS coffee_consumer
FROM city;

-- ------------------------------------------------------------------------------

/*
 Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales 
across all cities in the last quarter of 2023?
*/
SELECT QUARTER(sale_date) as quarter, SUM(total) AS total_revenue
FROM sales
WHERE YEAR(sale_date) = 2023
GROUP BY QUARTER(sale_date)
ORDER BY 1;

-- ----------------------------------------------------------------------------------
/*
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?
*/
SELECT p.product_name,COUNT(s.sale_id) AS total_order
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- ----------------------------------------------------------------------
/*
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city
*/

SELECT c.city_name, SUM(s.total) as total_sales,
COUNT(DISTINCT s.customer_id) as total_cx,
ROUND((SUM(s.total)/COUNT(DISTINCT s.customer_id)),2) as avg_sale_cx
FROM city c
JOIN customers cc ON cc.city_id = c.city_id
JOIN sales s ON s.customer_id = cc.customer_id
GROUP BY 1
ORDER BY 2 DESC;

-- -----------------------------------------------------------------------------------
/*
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)
*/
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- ----------------------------------------------------------------------
/*
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
*/
SELECT * FROM(
SELECT ci.city_name,p.product_name,SUM(s.total) AS total_sales,
DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY SUM(s.total) DESC) AS dnk
FROM sales s
JOIN products p ON p.product_id = s.product_id
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1,2
ORDER BY 1) AS t1
WHERE dnk<=3;

-- ---------------------------------------------------------------------
/*
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
*/
SELECT ci.city_name, COUNT(DISTINCT c.customer_id) as unique_cx
FROM sales s 
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- --------------------------------------------------------------------------

/*
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
*/
WITH city_sale AS(
SELECT ci.city_name,
COUNT(DISTINCT s.customer_id) AS unique_cx,
ROUND((SUM(s.total)/COUNT(DISTINCT s.customer_id)),2) AS avg_sale_pr_cx
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
GROUP BY ci.city_name
)

SELECT c.city_name,c.estimated_rent,cs.unique_cx,cs.avg_sale_pr_cx,
ROUND(c.estimated_rent/cs.unique_cx,2) AS avg_rent_per_cx
FROM city c
JOIN city_sale cs ON cs.city_name = c.city_name
ORDER BY 4 DESC;

-- --------------------------------------------------------------------------------
/*
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
*/
WITH monthly_sales AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),

growth_ratio AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale* 100, 2
		) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL;
    
-- ----------------------------------------------------------------------------
/*
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
*/

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent/ct.total_cx
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.
*/