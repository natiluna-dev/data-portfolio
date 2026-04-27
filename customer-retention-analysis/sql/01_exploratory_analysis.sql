-- =========================================================
-- Customer Retention Analysis
-- File: 01_exploratory_analysis.sql
-- Purpose:
-- Explore customer distribution, service mix, charges, and
-- tenure patterns before KPI analysis.
-- =========================================================

-- Base table:
-- customer_churn_cleaned

-- =========================================================
-- 1. Total customers
-- =========================================================
SELECT COUNT(*) as total_customers
FROM customer_churn_cleaned;

-- =========================================================
-- 2. Overall churn distribution
-- =========================================================
SELECT 
	churn, 
    COUNT(*) as customers, 
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY churn;

-- =========================================================
-- 3. Customer distribution by gender
-- =========================================================
SELECT 
	gender, 
    COUNT(*) as customers, 
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY gender;

-- =========================================================
-- 4. Customer distribution by senior citizen
-- =========================================================
SELECT 
	CASE WHEN senior_citizen = 0 THEN 'No' ELSE 'Yes' END AS senior_citizen, 
    COUNT(*) AS customers, 
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY senior_citizen
ORDER BY customers DESC;

-- =========================================================
-- 5. Customer distribution by partner and dependents
-- =========================================================
SELECT 
	partner, 
    dependents, 
    COUNT(*) AS customers,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY partner, dependents
ORDER BY customers DESC;

-- =========================================================
-- 6. Customer distribution by contract type
-- =========================================================
SELECT 
	contract, 
    COUNT(*) AS customers, 
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY customers DESC;

-- =========================================================
-- 7. Customer distribution by payment method
-- =========================================================
SELECT 
	payment_method, 
    COUNT(*) AS customers, 
	ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100 ,2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY payment_method
ORDER BY customers DESC;

-- =========================================================
-- 8. Customer distribution by internet service
-- =========================================================
SELECT 
	internet_service, 
    COUNT(*) AS customers, 
	ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100 ,2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY internet_service
ORDER BY customers DESC;

-- =========================================================
-- 9. Monthly charges summary statistics
-- =========================================================
SELECT 
	ROUND(MIN(monthly_charges), 2) AS min_monthly_charges, 
    ROUND(MAX(monthly_charges), 2) AS max_monthly_charges,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customer_churn_cleaned;

-- =========================================================
-- 10. Total charges summary statistics
-- =========================================================
SELECT 
	ROUND(MIN(total_charges) ,2) AS min_total_charges, 
    ROUND(MAX(total_charges) ,2) AS max_total_charges, 
    ROUND(AVG(total_charges) ,2) AS avg_total_charges,
    SUM(CASE WHEN total_charges IS NULL THEN 1 ELSE 0 END) AS null_total_charges
FROM customer_churn_cleaned;

-- =========================================================
-- 11. Tenure summary statistics
-- =========================================================
SELECT 
	ROUND(MIN(tenure) ,2) AS min_tenure, 
    ROUND(MAX(tenure) ,2) AS max_tenure, 
    ROUND(AVG(tenure) ,2) AS avg_tenure
FROM customer_churn_cleaned;

-- =========================================================
-- 12. Tenure bucket distribution
-- =========================================================
SELECT 
    CASE 
        WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
        ELSE '49+ months'
    END AS tenure_bucket,
    COUNT(*) AS customers,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_customers
FROM customer_churn_cleaned
GROUP BY tenure_bucket
ORDER BY 
    CASE tenure_bucket
        WHEN '0-12 months' THEN 1
        WHEN '13-24 months' THEN 2
        WHEN '25-48 months' THEN 3
        ELSE 4
    END;

-- =========================================================
-- 13. Average tenure by churn status
-- =========================================================
SELECT 
	churn, 
    ROUND(AVG(tenure), 2) AS avg_tenure
FROM customer_churn_cleaned
GROUP BY churn;

-- =========================================================
-- 14. Average monthly charges by contract
-- =========================================================
SELECT 
	contract, 
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY avg_monthly_charges DESC;

-- =========================================================
-- 15. Average total charges by contract
-- =========================================================
SELECT 
	contract, 
    ROUND(AVG(total_charges), 2) AS avg_total_charges
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY avg_total_charges DESC;
