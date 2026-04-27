-- =========================================================
-- Customer Retention Analysis
-- File: 04_business_questions.sql
-- Purpose:
-- Answer stakeholder-oriented business questions using the
-- cleaned churn dataset.
-- =========================================================

-- Base table:
-- customer_churn_cleaned

-- Note:
-- Some KPI cuts also exist in 02_kpi_analysis.sql.
-- Here they are kept only when they directly answer a business question.
-- Segment names are intentional:
-- risk_segment = contract + tenure + support/security risk factors.
-- service_bundle = service combination among churned customers.
-- priority_segment = commercial group ranked for retention action.

-- =========================================================
-- 1. Which customer segment has the highest churn risk?
-- =========================================================
-- Combines contract, tenure and support services to find practical risk groups.
-- The CTE prepares readable labels before calculating the final segment metrics.
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
-- Keeps segments with enough customers and ranks them by churn risk and revenue exposure.
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
-- 2. Are shorter contracts associated with higher churn?
-- =========================================================
-- Same KPI as 02_kpi_analysis.sql, included here because it directly answers the question.
-- Groups customers by contract type and compares churn rate across contract lengths.
SELECT
    contract,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 3. Do newer customers churn more often?
-- =========================================================
-- Buckets match the rest of the project for easier comparison.
-- The CTE converts numeric tenure into business-friendly customer age groups.
WITH base AS (
    SELECT
        churn,
        CASE
            WHEN tenure BETWEEN 0 AND 12 THEN '0-12 months'
            WHEN tenure BETWEEN 13 AND 24 THEN '13-24 months'
            WHEN tenure BETWEEN 25 AND 48 THEN '25-48 months'
            ELSE '49+ months'
        END AS tenure_bucket
    FROM customer_churn_cleaned
)
-- Compares churn rate across tenure buckets to see whether newer customers are riskier.
SELECT
    tenure_bucket,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM base
GROUP BY tenure_bucket
ORDER BY
    CASE tenure_bucket
        WHEN '0-12 months' THEN 1
        WHEN '13-24 months' THEN 2
        WHEN '25-48 months' THEN 3
        ELSE 4
    END;

-- =========================================================
-- 4. Do higher monthly charges relate to higher churn?
-- =========================================================
-- First compare averages, then compare simple charge bands.
-- Descriptive comparison only: average charges by churn status.
-- Use the charge-band query below for a more interpretable business cut.
SELECT
    churn,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customer_churn_cleaned
GROUP BY churn;

-- This CTE creates broad monthly charge bands for a second, easier-to-read view.
WITH charge_bands AS (
    SELECT
        CASE
            WHEN monthly_charges < 35 THEN '< 35'
            WHEN monthly_charges <= 70 THEN '35 - 70'
            ELSE '> 70'
        END AS monthly_charge_band,
        churn
    FROM customer_churn_cleaned
)
-- Compares churn rate by price band to show whether higher charges are linked to churn.
SELECT
    monthly_charge_band,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM charge_bands
GROUP BY monthly_charge_band
ORDER BY
    CASE monthly_charge_band
        WHEN '< 35' THEN 1
        WHEN '35 - 70' THEN 2
        ELSE 3
    END;

-- =========================================================
-- 5. Which payment methods show the highest churn?
-- =========================================================
-- Groups customers by payment method and ranks the methods with the highest churn rate.
SELECT
    payment_method,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- =========================================================
-- 6. Are support-related services linked to lower churn?
-- =========================================================
-- Compares support services in one output table.
-- Filter to customers with internet service so "No internet service" does not distort
-- the comparison between customers who could actually adopt these support features.
-- UNION ALL stacks three similar service checks into one comparable result set.
SELECT
    'Tech Support' AS service,
    tech_support AS service_status,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
WHERE internet_service <> 'No'
GROUP BY tech_support
UNION ALL
SELECT
    'Online Security' AS service,
    online_security AS service_status,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
WHERE internet_service <> 'No'
GROUP BY online_security
UNION ALL
SELECT
    'Online Backup' AS service,
    online_backup AS service_status,
    COUNT(*) AS customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS churn_rate_pct
FROM customer_churn_cleaned
WHERE internet_service <> 'No'
GROUP BY online_backup
ORDER BY service, churn_rate_pct DESC;

-- =========================================================
-- 7. Which service combinations are common among churned customers?
-- =========================================================
-- Looks only at churned customers to show the most common churn profiles.
-- The CTE filters to churned customers first, then standardizes service labels.
WITH base AS (
    SELECT
        customer_id,
        contract,
        internet_service,
        CASE
            WHEN tech_support = 'No' THEN 'No tech support'
            WHEN tech_support = 'Yes' THEN 'With tech support'
            ELSE 'No internet service'
        END AS tech_support_group,
        CASE
            WHEN online_security = 'No' THEN 'No online security'
            WHEN online_security = 'Yes' THEN 'With online security'
            ELSE 'No internet service'
        END AS online_security_group,
        CASE
            WHEN online_backup = 'No' THEN 'No online backup'
            WHEN online_backup = 'Yes' THEN 'With online backup'
            ELSE 'No internet service'
        END AS online_backup_group,
        CASE
            WHEN device_protection = 'No' THEN 'No device protection'
            WHEN device_protection = 'Yes' THEN 'With device protection'
            ELSE 'No internet service'
        END AS device_protection_group
    FROM customer_churn_cleaned
    WHERE churn = 'Yes'
)
-- Calculates each service bundle's share of all churned customers.
SELECT
    CONCAT(
        contract, ' | ',
        internet_service, ' | ',
        tech_support_group, ' | ',
        online_security_group, ' | ',
        online_backup_group, ' | ',
        device_protection_group
    ) AS service_bundle,
    COUNT(*) AS churned_customers,
    ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_of_churned_customers
FROM base
GROUP BY service_bundle
ORDER BY pct_of_churned_customers DESC;

-- =========================================================
-- 8. Which customer groups represent the greatest revenue risk?
-- =========================================================
-- Also ranks where retention efforts should be focused first.
-- First, summarize churn and revenue metrics by contract, payment method and internet service.
-- This uses a commercial group because retention actions usually depend on plan/payment/service.
-- Keep only segments with enough customers so the ranking reflects actionable groups,
-- not tiny segments with unstable churn rates.
WITH priority_segment_summary AS (
    SELECT
        CONCAT(contract, ' | ', payment_method, ' | ', internet_service) AS priority_segment,
        COUNT(*) AS customers,
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS churn_rate_pct_raw,
        ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS revenue_at_risk
    FROM customer_churn_cleaned
    GROUP BY priority_segment
    HAVING COUNT(*) >= 50
),
ranked_priority_segments AS (
    -- Then add revenue share and a priority rank with revenue at risk first, because
    -- this table is meant to prioritize commercial retention action.
    SELECT
        priority_segment,
        customers,
        churned_customers,
        ROUND(churn_rate_pct_raw, 2) AS churn_rate_pct,
        revenue_at_risk,
        ROUND(
            revenue_at_risk / NULLIF(SUM(revenue_at_risk) OVER(), 0) * 100,
            2
        ) AS revenue_at_risk_pct,
        DENSE_RANK() OVER(
            ORDER BY revenue_at_risk DESC, churn_rate_pct_raw DESC, customers DESC
        ) AS priority_rank
    FROM priority_segment_summary
)
-- Final output: a single business-priority table for retention actions.
SELECT
    priority_rank,
    priority_segment,
    customers,
    churned_customers,
    churn_rate_pct,
    revenue_at_risk,
    revenue_at_risk_pct
FROM ranked_priority_segments
ORDER BY priority_rank;
