-- =========================================
-- Level 1 — Basic
-- =========================================

-- =========================================================
-- 1) Calculate delivered revenue from completed sales
-- =========================================================
-- Product revenue excludes freight. Gross order value includes product price plus freight.
-- Only delivered orders are included to reflect successfully completed transactions
SELECT 
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_revenue,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- =========================================================
-- 2) Count total number of delivered orders
-- =========================================================
-- This represents the total volume of completed transactions in the dataset
SELECT 
    COUNT(*) AS total_delivered_orders
FROM orders
WHERE order_status = 'delivered';

-- =========================================================
-- 3) Calculate monthly revenue based on purchase date
-- =========================================================
-- Helps identify sales trends and seasonality over time
-- Aggregation is done at month level using order purchase timestamp
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
    ROUND(SUM(oi.price), 2) AS monthly_product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS monthly_freight_revenue,
	ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_gross_order_value
FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;

-- =========================================================
-- 4) Count monthly number of delivered orders
-- =========================================================
-- Useful to analyze changes in order volume and demand over time
-- Can be compared with revenue trends to identify changes in average order value
SELECT 
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY DATE_FORMAT(order_purchase_timestamp, '%Y-%m')
ORDER BY order_month;
    
    
    
