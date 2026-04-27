-- =========================================
-- Level 4 — KPI & Business Metrics
-- =========================================

-- =========================================================
-- 14) Sales concentration by category
-- =========================================================
-- Measures how much delivered gross order value is concentrated in the top product categories.
-- Includes each category's revenue share, cumulative percentage, and revenue rank.
WITH revenue_per_category AS (
	SELECT 
		COALESCE(pc.product_category_name_english, 'Unknown') AS category,
		ROUND(SUM(oi.price), 2) AS product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_category_value
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id 
	LEFT JOIN products p ON p.product_id = oi.product_id
	LEFT JOIN product_category_name_translation pc ON p.product_category_name = pc.product_category_name
	WHERE o.order_status = 'delivered'
	GROUP BY COALESCE(pc.product_category_name_english, 'Unknown')
), concentration_by_category AS ( 
	SELECT 
		category, 
		gross_category_value,
		ROUND(gross_category_value / SUM(gross_category_value) OVER() * 100, 2) AS gross_revenue_pct, 
		DENSE_RANK() OVER(ORDER BY gross_category_value DESC) AS rnk
	FROM revenue_per_category
) 
SELECT 
	category, 
    gross_category_value,
    gross_revenue_pct,
	ROUND(SUM(gross_revenue_pct) OVER(ORDER BY gross_revenue_pct DESC), 2) AS running_pct, 
    rnk
FROM concentration_by_category
WHERE rnk <= 10
ORDER BY rnk; 

-- =========================================================
-- 15) Customer segmentation by historical spend
-- =========================================================
-- Groups customers into High, Mid, and Low value segments based on delivered gross spend.
-- NTILE(3) is used to split customers into three equally sized groups.
-- This is historical spend segmentation, not a predictive lifetime value model.
WITH customer_lifetime_value AS (
	SELECT 
		c.customer_unique_id,  
		ROUND(SUM(oi.price), 2) AS product_spent,
		ROUND(SUM(oi.freight_value), 2) AS freight_spent,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_spent, 
        COUNT(DISTINCT o.order_id) AS total_orders 
	FROM orders o 
	JOIN order_items oi ON o.order_id = oi.order_id
    JOIN customers c ON o.customer_id = c.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
), segmentation AS(
SELECT 
	customer_unique_id, 
    gross_spent, 
    total_orders,
    NTILE(3) OVER(ORDER BY gross_spent desc) AS gross_spent_group
FROM customer_lifetime_value
) 
SELECT 
	'High' AS segment, 
	count(*) AS customers, 
    ROUND(AVG(gross_spent), 2) AS avg_spent
FROM segmentation
where gross_spent_group = 1
UNION ALL
SELECT 
	'Mid' AS segment, 
	count(*) AS customers, 
    ROUND(AVG(gross_spent), 2) AS avg_spent
FROM segmentation
where gross_spent_group = 2
UNION ALL 
SELECT 
	'Low' AS segment, 
	count(*) AS customers, 
    ROUND(AVG(gross_spent), 2) AS avg_spent
FROM segmentation
where gross_spent_group = 3;

-- =========================================================
-- 16) Revenue trends over time
-- =========================================================
-- Provides a comprehensive view of revenue evolution, including monthly revenue,
-- month-over-month growth, cumulative revenue, and rolling average trends.
-- This helps identify overall business growth patterns, volatility, and seasonality.
WITH revenue_per_month AS (
	SELECT 
		DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month, 
		ROUND(SUM(oi.price), 2) AS month_product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS month_freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS month_gross_order_value
	FROM orders o 
	JOIN order_items oi on o.order_id = oi.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY purchase_month
), monthly_comparison AS (
	SELECT 
		purchase_month, 
		month_gross_order_value, 
		LAG(month_gross_order_value) OVER(ORDER BY purchase_month) AS previous_month_gross_order_value
	FROM revenue_per_month
) 
SELECT 
	purchase_month, 
    month_gross_order_value, 
    previous_month_gross_order_value, 
    ROUND((month_gross_order_value - previous_month_gross_order_value)/ NULLIF(previous_month_gross_order_value, 0) * 100, 2) AS mom_growth_pct, 
    ROUND(SUM(month_gross_order_value) OVER(ORDER BY purchase_month), 2) AS cumulative_gross_order_value,
    ROUND(AVG(month_gross_order_value) OVER (ORDER BY purchase_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_3m
FROM monthly_comparison
ORDER BY purchase_month;

-- =========================================================
-- 17) Repeat purchase indicators
-- =========================================================
-- This query measures customer retention behavior by classifying customers as one-time or repeat buyers.
-- Only delivered orders are considered to reflect completed purchases.
-- customer_unique_id is used instead of customer_id to correctly identify the same customer across multiple orders.
-- The final output shows the number and percentage of customers in each purchase type segment.
-- A high share of one-time customers may indicate an opportunity to improve retention and repeat purchase behavior.
WITH customer_total_orders AS (
	SELECT 
		c.customer_unique_id, 
        COUNT(o.order_id) AS total_orders
	FROM orders o
	JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
), 
totals AS(
	SELECT  
		customer_unique_id, 
        total_orders, 
		COUNT(*) OVER() AS total_customers,
		CASE 
			WHEN total_orders = 1 THEN 'One-time' 
			ELSE 'Repeat' 
		END AS purchase_type
	FROM customer_total_orders
) 
SELECT 
	purchase_type, 
    COUNT(customer_unique_id) AS customers, 
    ROUND(COUNT(customer_unique_id) / MAX(total_customers) * 100.0, 2) AS pct 
FROM totals
GROUP BY purchase_type;

-- =========================================================
-- 18) Category growth opportunities
-- =========================================================
-- 18A) Category growth opportunities - monthly detailed view
-- =========================================================
-- Calculates monthly revenue and month-over-month growth percentage per category.
-- Helps identify trends, seasonality, and volatility.
WITH revenue_per_category AS (
	SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
		ROUND(SUM(oi.price), 2) AS monthly_product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS monthly_freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gross_order_value, 
        COALESCE(pct.product_category_name_english, 'Unknown') AS category
	FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, 'Unknown'), DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
), 
monthly_comparison AS (
	SELECT 
		purchase_month, 
		monthly_gross_order_value, 
		category, 
		LAG(monthly_gross_order_value) OVER(PARTITION BY category ORDER BY purchase_month) AS previous_month_gross_order_value
	FROM revenue_per_category
),
category_growth AS (
	SELECT
		category,
        purchase_month,
        monthly_gross_order_value,
        previous_month_gross_order_value,
        ROUND((monthly_gross_order_value - previous_month_gross_order_value) / NULLIF(previous_month_gross_order_value, 0) * 100.0, 2) AS growth_pct
	FROM monthly_comparison
)
SELECT 
		category, 
        purchase_month, 
		monthly_gross_order_value,     
        previous_month_gross_order_value,
		growth_pct
FROM category_growth
ORDER BY category, purchase_month;

-- =========================================================
-- 18B) Category growth opportunities - aggregated summary
-- =========================================================
-- Calculates average monthly growth per category.
-- Used to identify high-performing and declining categories.
-- Interpret results carefully for low-volume categories, because small absolute changes
-- can create very high percentage growth.
WITH revenue_per_category AS (
	SELECT
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
		ROUND(SUM(oi.price), 2) AS monthly_product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS monthly_freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gross_order_value, 
        COALESCE(pct.product_category_name_english, 'Unknown') AS category
	FROM orders o 
    JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
    WHERE o.order_status = 'delivered'
    GROUP BY COALESCE(pct.product_category_name_english, 'Unknown'), DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
), 
monthly_comparison AS (
	SELECT 
		purchase_month, 
		monthly_gross_order_value, 
		category, 
		LAG(monthly_gross_order_value) OVER(PARTITION BY category ORDER BY purchase_month) AS previous_month_gross_order_value
	FROM revenue_per_category
),
category_growth AS (
	SELECT
		category,
        purchase_month,
        monthly_gross_order_value,
        previous_month_gross_order_value,
        ROUND((monthly_gross_order_value - previous_month_gross_order_value) / NULLIF(previous_month_gross_order_value, 0) * 100.0, 2) AS growth_pct
	FROM monthly_comparison
)
SELECT 
	category, 
	ROUND(AVG(growth_pct), 2) AS avg_growth
FROM category_growth
GROUP BY category
ORDER BY avg_growth DESC;

-- =========================================================
-- 19) SQL/Pandas reconciliation metrics
-- =========================================================
-- These metrics are designed to match the Pandas reconciliation table.
-- They validate that filtering, joins, and metric definitions are consistent across tools.
SELECT
    COUNT(*) AS delivered_item_rows,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_order_value,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS product_aov,
    ROUND(SUM(oi.price + oi.freight_value) / COUNT(DISTINCT o.order_id), 2) AS gross_aov
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';
