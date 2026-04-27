-- =========================================
-- Level 3 — Advanced
-- =========================================

-- =========================================================
-- 9)	Category gross value contribution
-- =========================================================
-- Calculates the percentage share of delivered gross order value by product category.
WITH categories_revenue AS (
	SELECT 
		COALESCE(pct.product_category_name_english, 'Unknown') AS category,
		ROUND(SUM(oi.price), 2) AS product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_category_value
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	LEFT JOIN products p ON oi.product_id = p.product_id
    LEFT JOIN product_category_name_translation pct ON pct.product_category_name = p.product_category_name
	WHERE o.order_status = 'delivered'
	GROUP BY COALESCE(pct.product_category_name_english, 'Unknown')
)
SELECT 
	category,
	gross_category_value,
	ROUND(gross_category_value / SUM(gross_category_value) OVER() * 100, 2) AS category_gross_value_contribution
FROM categories_revenue
ORDER BY gross_category_value DESC; 

-- =========================================================
-- 10)	Top 10 customers by delivered revenue
-- =========================================================
-- Identifies the customers who generated the highest delivered revenue.
-- Note: customer_unique_id is used instead of customer_id to aggregate revenue at customer level,
-- since a single customer can have multiple customer_id entries (one per order).
SELECT 
	c.customer_unique_id, 
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_customer_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY gross_customer_value DESC
LIMIT 10; 

-- =========================================================
-- 11) Running gross order value by month
-- =========================================================
-- Tracks cumulative delivered gross order value over time.
WITH revenue_per_month AS (
	SELECT 
		DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
		ROUND(SUM(oi.price), 2) AS monthly_product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS monthly_freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gross_order_value
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
) 
SELECT 
	purchase_month,
    monthly_gross_order_value,
    ROUND(SUM(monthly_gross_order_value) OVER (ORDER BY purchase_month), 2) AS running_gross_order_value
FROM revenue_per_month
ORDER BY purchase_month;

-- =========================================================
-- 12) Month-over-month revenue growth
-- =========================================================
-- Compares each month's delivered revenue against the previous month.
WITH revenue_per_month AS (
	SELECT 
		DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
		ROUND(SUM(oi.price), 2) AS monthly_product_revenue,
		ROUND(SUM(oi.freight_value), 2) AS monthly_freight_revenue,
		ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gross_order_value
	FROM orders o
	JOIN order_items oi ON o.order_id = oi.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') 
), monthly_comparison AS (
	SELECT 
		purchase_month,
        monthly_gross_order_value,
		LAG(monthly_gross_order_value) OVER (ORDER BY purchase_month) AS previous_month_gross_order_value
	FROM revenue_per_month
)
SELECT 
	purchase_month, 
    monthly_gross_order_value, 
    previous_month_gross_order_value, 
    ROUND((monthly_gross_order_value - previous_month_gross_order_value) / NULLIF(previous_month_gross_order_value, 0) * 100, 2) AS mom_growth_pct
FROM monthly_comparison
ORDER BY purchase_month;

-- =========================================================
-- 13) Top 5 categories by monthly revenue with previous month comparison
-- =========================================================
-- Ranks categories by monthly delivered revenue within each month and compares each category's revenue to its previous month's value.
WITH category_monthly_gross_order_value AS (
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
), monthly_comparison AS (
SELECT
	*,
    DENSE_RANK() OVER (PARTITION BY purchase_month ORDER BY monthly_gross_order_value DESC) AS category_rank,
    LAG(monthly_gross_order_value) OVER(PARTITION BY category ORDER BY purchase_month) AS previous_month_gross_order_value
FROM category_monthly_gross_order_value
) 
SELECT
	purchase_month, 
    monthly_gross_order_value, 
    category, 
    category_rank, 
    previous_month_gross_order_value
FROM monthly_comparison
WHERE category_rank <= 5
ORDER BY purchase_month, category_rank;
