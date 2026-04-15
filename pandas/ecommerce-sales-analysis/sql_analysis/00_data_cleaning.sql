-- =========================================
-- Data Cleaning, Validation & Integrity Checks
-- Olist E-commerce Dataset
-- Purpose:
-- Prepare raw imported CSV tables for analysis by:
-- - inspecting schema and source data quality
-- - replacing blank strings with NULL
-- - validating and converting date columns from TEXT to DATETIME
-- - converting imported TEXT columns to VARCHAR
-- - defining primary and foreign keys when referential integrity allows
-- - documenting integrity issues that must be handled in analysis queries
-- =========================================

USE ecommerce; 

-- =========================================================
-- 1) INITIAL SCHEMA INSPECTION
-- =========================================================

-- Review imported structures before applying transformations
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE product_category_name_translation; 

-- =========================================================
-- 2) BACKUP TABLES BEFORE TRANSFORMATIONS
-- =========================================================

-- Create a backup copy of order_items before applying any changes
CREATE TABLE order_items_copy LIKE order_items;

INSERT INTO order_items_copy
SELECT * FROM order_items;

-- =========================================================
-- 3) SOURCE DATA VALIDATION
-- =========================================================

-- Check existing order status values to understand source consistency
SELECT 
	DISTINCT order_status
FROM orders
ORDER BY order_status;

-- Count blank date fields in orders
SELECT 
	SUM(order_purchase_timestamp='') AS blank_order_purchase_timestamp, 
	SUM(order_approved_at='') AS blank_order_approved_at, 
    SUM(order_delivered_carrier_date='') AS blank_order_delivered_carrier_date, 
    SUM(order_delivered_customer_date='') AS blank_order_delivered_customer_date, 
    SUM(order_estimated_delivery_date='') AS blank_order_estimated_delivery_date
FROM orders;

-- Count blank date fields in order_items
SELECT 
	SUM(shipping_limit_date='') AS blank_shipping_limit_date 
FROM order_items;

-- Identify product_ids present in order_items but missing in products
-- These unmatched records prevent foreign key enforcement
SELECT
    COUNT(DISTINCT oi.product_id) AS missing_product_ids
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- List product_ids with no matching record in products
SELECT DISTINCT
    oi.product_id
FROM order_items oi
LEFT JOIN products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Identify product categories that exist in products but have no translation mapping
SELECT
    COUNT(DISTINCT p.product_category_name) AS missing_categories
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;

-- =========================================================
-- 4) REPLACE BLANK STRINGS WITH NULL
-- =========================================================

UPDATE orders
SET order_purchase_timestamp = NULL
WHERE TRIM(order_purchase_timestamp) = ''; 

UPDATE orders
SET order_approved_at = NULL
WHERE TRIM(order_approved_at) = '';

UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE TRIM(order_delivered_carrier_date) = '' ;

UPDATE orders
SET order_delivered_customer_date = NULL
WHERE TRIM(order_delivered_customer_date) = ''  ;

UPDATE orders
SET order_estimated_delivery_date = NULL
WHERE TRIM(order_estimated_delivery_date) = '' ;

UPDATE order_items
SET shipping_limit_date = NULL
WHERE TRIM(shipping_limit_date) = '' ;

-- =========================================================
-- 5) VALIDATE DATETIME FORMAT BEFORE ALTERING
-- =========================================================

-- These queries should return 0 rows if all non-null values are valid datetimes
SELECT order_purchase_timestamp
FROM orders
WHERE order_purchase_timestamp IS NOT NULL
  AND STR_TO_DATE(order_purchase_timestamp, '%Y-%m-%d %H:%i:%s') IS NULL;
  
SELECT order_approved_at
FROM orders
WHERE order_approved_at IS NOT NULL
	AND STR_TO_DATE(order_approved_at , '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT order_delivered_carrier_date
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL
	AND STR_TO_DATE(order_delivered_carrier_date, '%Y-%m-%d %H:%i:%s') IS NULL;
    
SELECT order_delivered_customer_date
FROM orders
WHERE order_delivered_customer_date IS NOT NULL
  AND STR_TO_DATE(order_delivered_customer_date, '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT order_estimated_delivery_date
FROM orders
WHERE order_estimated_delivery_date IS NOT NULL
  AND STR_TO_DATE(order_estimated_delivery_date, '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT shipping_limit_date
FROM order_items
WHERE shipping_limit_date IS NOT NULL
  AND STR_TO_DATE(shipping_limit_date, '%Y-%m-%d %H:%i:%s') IS NULL;

-- =========================================================
-- 6) CONVERT DATE COLUMNS FROM TEXT TO DATETIME
-- =========================================================

ALTER TABLE orders
MODIFY COLUMN order_purchase_timestamp DATETIME,
MODIFY COLUMN order_approved_at DATETIME,
MODIFY COLUMN order_delivered_carrier_date DATETIME,
MODIFY COLUMN order_delivered_customer_date DATETIME,
MODIFY COLUMN order_estimated_delivery_date DATETIME;

ALTER TABLE order_items
MODIFY COLUMN shipping_limit_date DATETIME;

-- =========================================================
-- 7) CONVERT IMPORTED TEXT COLUMNS TO VARCHAR
-- =========================================================

ALTER TABLE orders
MODIFY COLUMN order_id VARCHAR(50),
MODIFY COLUMN customer_id VARCHAR(50),
MODIFY COLUMN order_status VARCHAR(50); 

ALTER TABLE order_items
MODIFY COLUMN order_id VARCHAR(50),
MODIFY COLUMN product_id VARCHAR(50),
MODIFY COLUMN seller_id VARCHAR(50); 

ALTER TABLE customers
MODIFY COLUMN customer_id VARCHAR(50),
MODIFY COLUMN customer_unique_id VARCHAR(50),
MODIFY COLUMN customer_zip_code_prefix VARCHAR(50),
MODIFY COLUMN customer_city VARCHAR(50),
MODIFY COLUMN customer_state VARCHAR(50); 

ALTER TABLE products
MODIFY COLUMN product_id VARCHAR(50),
MODIFY COLUMN product_category_name VARCHAR(100);

ALTER TABLE product_category_name_translation
MODIFY COLUMN product_category_name VARCHAR(100),
MODIFY COLUMN product_category_name_english VARCHAR(100);

-- =========================================================
-- 8) PRIMARY KEYS
-- =========================================================

ALTER TABLE orders
ADD PRIMARY KEY (order_id);

ALTER TABLE order_items
ADD PRIMARY KEY (order_id, order_item_id);

ALTER TABLE customers
ADD PRIMARY KEY (customer_id);

ALTER TABLE products
ADD PRIMARY KEY (product_id);

ALTER TABLE product_category_name_translation
ADD PRIMARY KEY (product_category_name);

-- =========================================================
-- 9) FOREIGN KEYS
-- =========================================================

-- orders - customers
ALTER TABLE orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);

-- order_items - orders
ALTER TABLE order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id)
REFERENCES orders(order_id);

-- order_items - products
-- Validation should return 0 unmatched product_id values before enforcing this relationship.
-- Analysis queries still use LEFT JOIN where category completeness must be preserved.

-- ALTER TABLE order_items
-- ADD CONSTRAINT fk_order_items_products
-- FOREIGN KEY (product_id)
-- REFERENCES products(product_id);

-- products - category translation
-- Not enforced due to missing category mappings in translation table.
-- LEFT JOIN will be used during analysis to preserve unmatched categories.

-- ALTER TABLE products
-- ADD CONSTRAINT fk_products_category
-- FOREIGN KEY (product_category_name)
-- REFERENCES product_category_name_translation (product_category_name);

-- =========================================================
-- 10) POST-CLEANING CHECK
-- =========================================================

-- Confirm final schema after transformations
DESCRIBE orders;
DESCRIBE order_items;
DESCRIBE customers;
DESCRIBE products;
DESCRIBE product_category_name_translation; 

-- =========================================================
-- 11) DATA QUALITY SUMMARY
-- =========================================================

-- These checks summarize the main validation results used to support analysis decisions.
-- Expected results from the raw CSV dataset:
-- - duplicate order_id values: 0
-- - duplicate customer_id values: 0
-- - repeated customer_unique_id values: 3,345
-- - duplicate product_id values: 0
-- - unmatched product_id values in order_items: 0
-- - product categories without English translation: 2
-- - products without category: 610
-- - negative price rows: 0
-- - negative freight rows: 0

SELECT
    'duplicate_order_id' AS check_name,
    COUNT(*) - COUNT(DISTINCT order_id) AS result
FROM orders
UNION ALL
SELECT
    'duplicate_customer_id' AS check_name,
    COUNT(*) - COUNT(DISTINCT customer_id) AS result
FROM customers
UNION ALL
SELECT
    'repeated_customer_unique_id' AS check_name,
    COUNT(*) - COUNT(DISTINCT customer_unique_id) AS result
FROM customers
UNION ALL
SELECT
    'duplicate_product_id' AS check_name,
    COUNT(*) - COUNT(DISTINCT product_id) AS result
FROM products
UNION ALL
SELECT
    'unmatched_product_id_in_order_items' AS check_name,
    COUNT(DISTINCT oi.product_id) AS result
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL
UNION ALL
SELECT
    'product_categories_without_translation' AS check_name,
    COUNT(DISTINCT p.product_category_name) AS result
FROM products p
LEFT JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
UNION ALL
SELECT
    'products_without_category' AS check_name,
    COUNT(*) AS result
FROM products
WHERE product_category_name IS NULL
UNION ALL
SELECT
    'negative_price_rows' AS check_name,
    COUNT(*) AS result
FROM order_items
WHERE price < 0
UNION ALL
SELECT
    'negative_freight_rows' AS check_name,
    COUNT(*) AS result
FROM order_items
WHERE freight_value < 0;
