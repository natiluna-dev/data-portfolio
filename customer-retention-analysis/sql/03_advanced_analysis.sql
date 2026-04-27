-- =========================================================
-- Customer Retention Analysis
-- File: 03_advanced_analysis.sql
-- Purpose:
-- Perform deeper segmentation and identify the most vulnerable
-- customer profiles through combined churn risk factors.
-- =========================================================

-- Base table:
-- customer_churn_cleaned

-- Note:
-- This file keeps some metric formulas visible on purpose.
-- That makes the analysis easier to follow at junior level.
-- Segment names are intentional:
-- risk_segment = contract + tenure + support/security risk factors.
-- commercial_segment = contract + payment method + internet service.

-- =========================================================
-- 1. Risk segment definition
-- =========================================================
-- Creates readable customer segments using contract, tenure and support services.
-- The CTE prepares labels first, so the final SELECT only has to group and count.
WITH base AS (
    SELECT
        customer_id,
        contract,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END AS tenure_bucket,
        CASE
            WHEN tech_support = 'No' THEN 'No tech support'
            WHEN tech_support = 'Yes' THEN 'With tech support'
            ELSE 'No internet service'
        END AS tech_support_group,
        CASE
            WHEN online_security = 'No' THEN 'No online security'
            WHEN online_security = 'Yes' THEN 'With online security'
            ELSE 'No internet service'
        END AS online_security_group
    FROM customer_churn_cleaned
)
-- Counts how many customers fall into each combined risk segment.
SELECT
    CONCAT(contract, ' | ', tenure_bucket, ' | ', tech_support_group, ' | ', online_security_group) AS risk_segment,
    COUNT(*) AS customers
FROM base
GROUP BY risk_segment
ORDER BY customers DESC, risk_segment;

-- =========================================================
-- 2. High-risk segment ranking
-- =========================================================
-- Adds churn and revenue metrics to the segment definition above.
-- The base CTE keeps the same segment labels as query 1 and adds churn/revenue fields.
WITH base AS (
    SELECT
        customer_id,
        contract,
        monthly_charges,
        churn,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END AS tenure_bucket,
        CASE
            WHEN tech_support = 'No' THEN 'No tech support'
            WHEN tech_support = 'Yes' THEN 'With tech support'
            ELSE 'No internet service'
        END AS tech_support_group,
        CASE
            WHEN online_security = 'No' THEN 'No online security'
            WHEN online_security = 'Yes' THEN 'With online security'
            ELSE 'No internet service'
        END AS online_security_group
    FROM customer_churn_cleaned
)
-- Ranks only meaningful segments, using at least 50 customers to avoid tiny groups.
WITH risk_segment_summary AS (
    SELECT
        CONCAT(contract, ' | ', tenure_bucket, ' | ', tech_support_group, ' | ', online_security_group) AS risk_segment,
        COUNT(*) AS customers,
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS churn_rate_pct_raw,
        ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
    FROM base
    GROUP BY risk_segment
    HAVING COUNT(*) >= 50
)
SELECT
    risk_segment,
    customers,
    churned_customers,
    ROUND(churn_rate_pct_raw, 2) AS churn_rate_pct,
    revenue_at_risk
FROM risk_segment_summary
ORDER BY churn_rate_pct_raw DESC, revenue_at_risk DESC;

-- =========================================================
-- 3. Export-ready risk segment table
-- =========================================================
-- Keeps the same risk segment logic in a table shape that is easy to export
-- to Pandas, Tableau, or CSV without recalculating business definitions.
WITH base AS (
    SELECT
        customer_id,
        monthly_charges,
        churn,
        contract,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END AS tenure_bucket,
        CASE
            WHEN tech_support = 'No' THEN 'No tech support'
            WHEN tech_support = 'Yes' THEN 'With tech support'
            ELSE 'No internet service'
        END AS tech_support_group,
        CASE
            WHEN online_security = 'No' THEN 'No online security'
            WHEN online_security = 'Yes' THEN 'With online security'
            ELSE 'No internet service'
        END AS online_security_group
    FROM customer_churn_cleaned
)
-- Adds readable dimensions plus churn and revenue metrics for downstream tools.
SELECT
    contract,
    tenure_bucket,
    tech_support_group,
    online_security_group,
    CONCAT(contract, ' | ', tenure_bucket, ' | ', tech_support_group, ' | ', online_security_group) AS risk_segment,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
FROM base
GROUP BY
    contract,
    tenure_bucket,
    tech_support_group,
    online_security_group,
    risk_segment
HAVING COUNT(*) >= 50
ORDER BY churn_rate_pct DESC, revenue_at_risk DESC;

-- =========================================================
-- 4. Churn by contract and payment method
-- =========================================================
-- Checks whether payment method changes churn behavior inside each contract type.
-- This is more specific than the KPI file, which analyzes these fields separately.
SELECT
    contract,
    payment_method,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY contract, payment_method
ORDER BY churn_rate_pct DESC, customers DESC;

-- =========================================================
-- 5. Churn by internet service and tech support
-- =========================================================
-- Compares support availability within each internet service type.
-- This helps separate "No support" from "No internet service".
SELECT
    internet_service,
    tech_support,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY internet_service, tech_support
ORDER BY churn_rate_pct DESC, customers DESC;

-- =========================================================
-- 6. Churn by tenure bucket and contract
-- =========================================================
-- Combines tenure and contract because this is more advanced than a single KPI cut.
-- The CTE creates the same tenure buckets used in the rest of the project.
WITH base AS (
    SELECT
        contract,
        churn,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END AS tenure_bucket
    FROM customer_churn_cleaned
)
-- Shows whether short-tenure customers behave differently depending on contract type.
SELECT
    tenure_bucket,
    contract,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM base
GROUP BY tenure_bucket, contract
ORDER BY
    CASE tenure_bucket
        WHEN '0-12 months' THEN 1
        WHEN '13-24 months' THEN 2
        WHEN '25-48 months' THEN 3
        ELSE 4
    END,
    churn_rate_pct DESC;

-- =========================================================
-- 7. Monthly charges band analysis
-- =========================================================
-- Groups monthly charges into simple bands to compare churn by price level.
-- These bands are intentionally broad so the output stays easy to read.
SELECT
    CASE
        WHEN monthly_charges < 35 THEN '< 35'
        WHEN monthly_charges <= 70 THEN '35 - 70'
        ELSE '> 70'
    END AS monthly_charge_band,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY monthly_charge_band
ORDER BY
    CASE monthly_charge_band
        WHEN '< 35' THEN 1
        WHEN '35 - 70' THEN 2
        ELSE 3
    END;

-- =========================================================
-- 8. Total charges band analysis
-- =========================================================
-- Groups lifetime charges into simple bands to compare churn by accumulated spend.
-- NULL total charges are kept visible as "Unknown" instead of being dropped.
SELECT
    CASE
        WHEN total_charges IS NULL THEN 'Unknown'
        WHEN total_charges <= 1000 THEN '< 1000'
        WHEN total_charges <= 3000 THEN '1000 - 3000'
        ELSE '> 3000'
    END AS total_charges_band,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY total_charges_band
ORDER BY
    CASE total_charges_band
        WHEN 'Unknown' THEN 1
        WHEN '< 1000' THEN 2
        WHEN '1000 - 3000' THEN 3
        ELSE 4
    END;

-- =========================================================
-- 9. Risk score model
-- =========================================================
-- Calculates the score once, then summarizes churn and revenue risk by level.
-- Each risk factor adds 1 point: monthly contract, low tenure, no support,
-- no online security, and monthly charges above the dataset average.
WITH scores AS (
    SELECT
        customer_id,
        monthly_charges,
        churn,
        (
            CASE WHEN contract = 'Month-to-month' THEN 1 ELSE 0 END +
            CASE WHEN tenure <= 12 THEN 1 ELSE 0 END +
            CASE WHEN tech_support = 'No' THEN 1 ELSE 0 END +
            CASE WHEN online_security = 'No' THEN 1 ELSE 0 END +
            CASE WHEN monthly_charges > AVG(monthly_charges) OVER() THEN 1 ELSE 0 END
        ) AS risk_score
    FROM customer_churn_cleaned
),
levels AS (
    -- Converts the numeric score into a readable risk level for business users.
    SELECT
        customer_id,
        monthly_charges,
        churn,
        risk_score,
        CASE
            WHEN risk_score <= 1 THEN 'Low'
            WHEN risk_score = 2 THEN 'Medium'
            WHEN risk_score = 3 THEN 'High'
            ELSE 'Very High'
        END AS risk_level
    FROM scores
)
-- Summarizes the score model with customer count, churn rate and revenue exposure.
SELECT
    risk_score,
    risk_level,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk,
    ROUND(
        SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END)
        / NULLIF(SUM(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END)) OVER(), 0) * 100,
        2
    ) AS revenue_at_risk_pct
FROM levels
GROUP BY risk_score, risk_level
ORDER BY risk_score;

-- =========================================================
-- 10. Top vulnerable commercial segments
-- =========================================================
-- Builds compact profile names from commercial attributes.
-- This is different from risk_segment: it focuses on how customers buy/pay,
-- not on tenure or support/security risk factors.
WITH commercial_segments AS (
    SELECT
        CONCAT(contract, ' | ', payment_method, ' | ', internet_service) AS commercial_segment,
        monthly_charges,
        churn
    FROM customer_churn_cleaned
)
-- Ranks commercial segments by churn rate, then revenue at risk, then size.
SELECT
    commercial_segment,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
FROM commercial_segments
GROUP BY commercial_segment
ORDER BY churn_rate_pct DESC, revenue_at_risk DESC, customers DESC;
