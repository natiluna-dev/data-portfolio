-- =========================================================
-- Customer Retention Analysis
-- File: 02_kpi_analysis.sql
-- Purpose:
-- Calculate the main retention and churn KPIs used to assess
-- customer risk and revenue exposure.
-- =========================================================

-- Base table:
-- customer_churn_cleaned

-- =========================================================
-- 1. Executive KPI summary
-- =========================================================
-- Summarizes customer retention, churn, and monthly revenue exposure.
SELECT 
	COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) AS retained_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS retention_rate_pct,
    ROUND(SUM(monthly_charges), 2) AS monthly_revenue,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END) / SUM(monthly_charges) * 100, 2) AS revenue_at_risk_pct
FROM customer_churn_cleaned;

-- =========================================================
-- 2. Churn rate by contract type
-- =========================================================
SELECT 
	contract, 
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 3. Churn rate by tenure bucket
-- =========================================================
SELECT 
	CASE
		WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
        ELSE '49+ months'
	END AS tenure_bucket,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY tenure_bucket
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 4. Churn rate by payment method
-- =========================================================
SELECT
	payment_method, 
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 5. Churn rate by internet service
-- =========================================================
SELECT
	internet_service, 
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 6. Churn rate by tech support
-- =========================================================
SELECT
	tech_support, 
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY tech_support
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 7. Churn rate by online security
-- =========================================================
SELECT
	online_security, 
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY online_security
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 8. Average charges by churn status
-- =========================================================
SELECT 
	churn,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(total_charges), 2) AS avg_total_charges
FROM customer_churn_cleaned
GROUP BY churn;

-- =========================================================
-- 9. Monthly revenue share by churn status
-- =========================================================
-- Shows how much current monthly revenue is tied to retained vs churned customers.
SELECT 
	churn,
    ROUND(SUM(monthly_charges), 2) AS monthly_revenue,
	ROUND(SUM(monthly_charges) / SUM(SUM(monthly_charges)) OVER() * 100, 2) AS monthly_revenue_share_pct
FROM customer_churn_cleaned
GROUP BY churn;

-- =========================================================
-- 10. Churn contribution by contract
-- =========================================================
-- Measures which contract types contribute the most churned customers.
SELECT 
	contract,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers, 
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) 
		/ NULLIF(SUM(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END)) OVER(), 0) * 100, 2) AS churn_contribution_pct
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY churn_contribution_pct DESC;

-- =========================================================
-- 11. Revenue at risk breakdown by contract
-- =========================================================
-- Breaks down the total revenue at risk from the executive summary by contract type.
SELECT 
	contract,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END) 
		/ NULLIF(SUM(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END)) OVER(), 0) * 100, 2) AS revenue_at_risk_pct
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY revenue_at_risk DESC;

-- =========================================================
-- 12. High-risk customer segments
-- =========================================================
-- Identifies sizable customer segments with high churn and revenue exposure.
SELECT
    contract,
    payment_method,
    internet_service,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
FROM customer_churn_cleaned
GROUP BY contract, payment_method, internet_service
HAVING COUNT(*) >= 50
ORDER BY churn_rate_pct DESC, revenue_at_risk DESC;
