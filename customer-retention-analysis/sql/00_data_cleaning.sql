-- ================================================================
-- Customer Retention Analysis
-- File: 00_data_cleaning.sql
-- Purpose:
-- Validate raw customer churn data and prepare a cleaned table
-- for downstream analysis.
-- ================================================================

-- =========================================================
-- 1. Initial inspection
-- =========================================================
SELECT * 
FROM customer_churn
LIMIT 10;

DESCRIBE customer_churn;

-- =========================================================
-- 2. Total row count
-- =========================================================
SELECT COUNT(*) AS total_rows
FROM customer_churn;

-- =========================================================
-- 3. Duplicate customerID check
-- =========================================================
SELECT 
    TRIM(customerID) AS customerID,
    COUNT(*) AS cust_id_count
FROM customer_churn
GROUP BY TRIM(customerID)
HAVING COUNT(*) > 1;

-- =========================================================
-- 4. Null and blank value checks
-- =========================================================
SELECT 
	SUM(CASE WHEN customerID IS NULL OR TRIM(customerID) = '' THEN 1 ELSE 0 END) AS missing_customerID,
    SUM(CASE WHEN churn IS NULL OR TRIM(churn) = ''  THEN 1 ELSE 0 END) AS missing_churn,
    SUM(CASE WHEN totalcharges IS NULL OR TRIM(totalcharges) = ''  THEN 1 ELSE 0 END) AS missing_totalcharges,
    SUM(CASE WHEN contract IS NULL OR TRIM(contract) = ''  THEN 1 ELSE 0 END) AS missing_contract
FROM customer_churn;

-- =========================================================
-- 5. Churn value validation
-- =========================================================
SELECT
	churn, 
    COUNT(*) as churn_count
FROM customer_churn
GROUP BY churn;

SELECT 
    churn, 
    COUNT(*) AS churn_count
FROM customer_churn
GROUP BY churn
HAVING TRIM(churn) NOT IN ('Yes', 'No')
    OR churn IS NULL
    OR TRIM(churn) = '';


-- =========================================================
-- 6. Categorical value inspection
-- =========================================================
SELECT
	gender, 
    COUNT(*) as count
FROM customer_churn
GROUP BY gender;

SELECT 
	SeniorCitizen, 
    COUNT(*) AS count
FROM customer_churn
GROUP BY SeniorCitizen;

SELECT
	Partner, 
    COUNT(*) as count
FROM customer_churn
GROUP BY Partner;

SELECT
	Dependents, 
    COUNT(*) as count
FROM customer_churn
GROUP BY Dependents;

SELECT
	PhoneService, 
    COUNT(*) as count
FROM customer_churn
GROUP BY PhoneService;

SELECT
	MultipleLines, 
    COUNT(*) as count
FROM customer_churn
GROUP BY MultipleLines;

SELECT
	InternetService, 
    COUNT(*) as count
FROM customer_churn
GROUP BY InternetService;

SELECT
	OnlineSecurity, 
    COUNT(*) as count
FROM customer_churn
GROUP BY OnlineSecurity;

SELECT
	OnlineBackup, 
    COUNT(*) as count
FROM customer_churn
GROUP BY OnlineBackup;

SELECT
	DeviceProtection, 
    COUNT(*) as count
FROM customer_churn
GROUP BY DeviceProtection;

SELECT
	TechSupport, 
    COUNT(*) as count
FROM customer_churn
GROUP BY TechSupport;

SELECT
	StreamingTV, 
    COUNT(*) as count
FROM customer_churn
GROUP BY StreamingTV;

SELECT
	StreamingMovies, 
    COUNT(*) as count
FROM customer_churn
GROUP BY StreamingMovies;

SELECT
	Contract, 
    COUNT(*) as count
FROM customer_churn
GROUP BY Contract;

SELECT 
	PaperlessBilling, 
    COUNT(*) AS count
FROM customer_churn
GROUP BY PaperlessBilling;

SELECT
	PaymentMethod, 
    COUNT(*) as count
FROM customer_churn
GROUP BY PaymentMethod;

-- =========================================================
-- 7. Numeric field validation
-- =========================================================

-- Validate MonthlyCharges numeric format
SELECT MonthlyCharges
FROM customer_churn
WHERE MonthlyCharges IS NULL
   OR TRIM(MonthlyCharges) = ''
   OR TRIM(MonthlyCharges) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- Validate tenure numeric format
SELECT tenure
FROM customer_churn
WHERE tenure IS NULL
   OR TRIM(tenure) = ''
   OR TRIM(tenure) NOT REGEXP '^[0-9]+$';

-- Validate SeniorCitizen expected values
SELECT SeniorCitizen, COUNT(*) AS customers
FROM customer_churn
GROUP BY SeniorCitizen
HAVING SeniorCitizen IS NULL
    OR SeniorCitizen NOT IN (0, 1);

-- Validate blank TotalCharges records before converting blanks to NULL
SELECT 
	customerID,
	tenure, 
    contract, 
    monthlyCharges, 
    totalcharges
FROM customer_churn
WHERE TotalCharges IS NULL
	OR TRIM(TotalCharges) = '';

SELECT COUNT(*) AS blank_totalcharges_with_nonzero_tenure
FROM customer_churn
WHERE (TotalCharges IS NULL OR TRIM(TotalCharges) = '')
  AND tenure <> 0;

SELECT totalcharges
FROM customer_churn
WHERE TRIM(totalcharges) <> ''
	AND TRIM(totalcharges) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- =========================================================
-- 8. Create cleaned table
-- =========================================================

-- trim categorical fields, cast numeric fields, convert blank TotalCharges to NULL
DROP TABLE IF EXISTS customer_churn_cleaned;

CREATE TABLE customer_churn_cleaned AS
SELECT 
	TRIM(customerID) AS customer_id,
    TRIM(gender) AS gender,
    CAST(SeniorCitizen AS UNSIGNED) AS senior_citizen,
    TRIM(Partner) AS partner,
    TRIM(Dependents) AS dependents,
    CAST(TRIM(tenure) AS UNSIGNED) AS tenure,
    TRIM(PhoneService) AS phone_service,
    TRIM(MultipleLines) AS multiple_lines,
    TRIM(InternetService) AS internet_service,
    TRIM(OnlineSecurity) AS online_security,
    TRIM(OnlineBackup) AS online_backup,
    TRIM(DeviceProtection) AS device_protection,
    TRIM(TechSupport) AS tech_support,
    TRIM(StreamingTV) AS streaming_tv,
    TRIM(StreamingMovies) AS streaming_movies,
    TRIM(Contract) AS contract,
    TRIM(PaperlessBilling) AS paperless_billing,
    TRIM(PaymentMethod) AS payment_method,
	CAST(TRIM(MonthlyCharges) AS DECIMAL(10,2)) AS monthly_charges,
    CAST(NULLIF(TRIM(TotalCharges), '') AS DECIMAL(10,2)) AS total_charges,
    TRIM(Churn) AS churn 
FROM customer_churn;

-- =========================================================
-- 9. Final validation
-- =========================================================

-- row count, nulls, churn distribution, min/max numeric checks
SELECT COUNT(*) AS cleaned_rows
FROM customer_churn_cleaned;

SELECT
  SUM(CASE WHEN total_charges IS NULL THEN 1 ELSE 0 END) AS null_total_charges
FROM customer_churn_cleaned;

SELECT 
	churn, 
    COUNT(*) AS count
FROM customer_churn_cleaned
GROUP BY churn;

SELECT
    (SELECT COUNT(*) FROM customer_churn) AS raw_rows,
    (SELECT COUNT(*) FROM customer_churn_cleaned) AS cleaned_rows;

SELECT
    MIN(tenure) AS min_tenure,
    MAX(tenure) AS max_tenure,
    MIN(monthly_charges) AS min_monthly_charges,
    MAX(monthly_charges) AS max_monthly_charges,
    MIN(total_charges) AS min_total_charges,
    MAX(total_charges) AS max_total_charges
FROM customer_churn_cleaned;
