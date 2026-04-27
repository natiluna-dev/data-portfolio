-- =========================================
-- Level 2 — Intermediate
-- =========================================

-- =========================================================
-- 5) Average Order Value (AOV)
-- =========================================================
-- Measures the average product revenue and gross value generated per completed order
-- DISTINCT is required because each order may contain multiple items,
-- which would otherwise overcount the number of orders after joining with order_items
-- Only delivered orders are included to reflect completed transactions
WITH totals AS (
SELECT 
	ROUND(SUM(oi.price), 2) AS product_revenue,
	ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
	ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_order_value,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
)
SELECT 
	product_revenue,
	freight_revenue,
	gross_order_value,
    total_delivered_orders,
	ROUND(product_revenue / total_delivered_orders, 2) AS product_aov,
	ROUND(gross_order_value / total_delivered_orders, 2) AS gross_aov
FROM totals; 

-- =========================================================
-- 6) Identify the top 10 products by gross order value
-- =========================================================
-- Product revenue excludes freight. Gross product value includes product price plus freight.
-- Helps highlight the products contributing the most to total sales
SELECT 
	oi.product_id,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_product_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY gross_product_value DESC
LIMIT 10;

-- =========================================================
-- 7) Identify the top 10 products by quantity sold
-- =========================================================
-- Measures product demand based on total units sold
-- Useful for comparing high-demand products against high-revenue products
SELECT 
	oi.product_id,
    COUNT(*) AS units_sold
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY units_sold DESC
LIMIT 10;

-- =========================================================
-- 8) Calculate revenue by product category
-- =========================================================
-- Aggregates completed sales at category level to identify top-performing segments
-- COALESCE is used to group missing category translations under 'Unknown'
-- LEFT JOINs preserve transactional records even when product or category mapping is missing
SELECT 
    COALESCE(pct.product_category_name_english, 'Unknown') AS category,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_category_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY COALESCE(pct.product_category_name_english, 'Unknown') 
ORDER BY gross_category_value DESC;
