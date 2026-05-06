-- ================================================================
-- Support Tickets Analysis
-- File: 00_data_cleaning.sql
-- Purpose:
-- Validate the raw support tickets dataset and create a cleaned table
-- for downstream analysis.
-- ================================================================

-- Base raw table:
-- support_tickets_raw
--
-- Output table:
-- support_tickets_cleaned
--
-- This script keeps the checks and the cleaning logic together so readers
-- can see how the final analytical table was validated and built.

USE support_tickets_analysis;

-- =========================================================
-- 1. Initial inspection
-- =========================================================
-- Preview the raw import, inspect the inferred structure, and confirm row count.
-- These checks help catch import issues before any transformation is applied.
SELECT *
FROM support_tickets_raw
LIMIT 10;

DESCRIBE support_tickets_raw;

SELECT COUNT(*) AS total_rows
FROM support_tickets_raw;

-- =========================================================
-- 2. Duplicate ticket ID check
-- =========================================================
-- Ticket ID should identify one support request.
-- Any result returned here should be investigated before using ticket counts.
SELECT
    TRIM(`Ticket ID`) AS ticket_id,
    COUNT(*) AS ticket_id_count
FROM support_tickets_raw
GROUP BY TRIM(`Ticket ID`)
HAVING COUNT(*) > 1;

-- =========================================================
-- 3. Null and blank value checks
-- =========================================================
-- Counts missing values in the fields used later for KPIs, segmentation, and dashboard outputs.
-- Blank strings are treated as missing because the raw CSV stores all fields as text.
SELECT
    SUM(CASE WHEN `Ticket ID` IS NULL OR TRIM(`Ticket ID`) = '' THEN 1 ELSE 0 END) AS missing_ticket_id,
    SUM(CASE WHEN `Ticket Status` IS NULL OR TRIM(`Ticket Status`) = '' THEN 1 ELSE 0 END) AS missing_ticket_status,
    SUM(CASE WHEN `Ticket Priority` IS NULL OR TRIM(`Ticket Priority`) = '' THEN 1 ELSE 0 END) AS missing_ticket_priority,
    SUM(CASE WHEN `Ticket Channel` IS NULL OR TRIM(`Ticket Channel`) = '' THEN 1 ELSE 0 END) AS missing_ticket_channel,
    SUM(CASE WHEN `First Response Time` IS NULL OR TRIM(`First Response Time`) = '' THEN 1 ELSE 0 END) AS missing_first_response_time,
    SUM(CASE WHEN `Time to Resolution` IS NULL OR TRIM(`Time to Resolution`) = '' THEN 1 ELSE 0 END) AS missing_time_to_resolution,
    SUM(CASE WHEN `Customer Satisfaction Rating` IS NULL OR TRIM(`Customer Satisfaction Rating`) = '' THEN 1 ELSE 0 END) AS missing_customer_satisfaction_rating
FROM support_tickets_raw;

-- =========================================================
-- 4. Distinct categorical value inspection
-- =========================================================
-- Reviews category values before standardization.
-- This confirms whether fields such as status and priority need cleanup rules.
SELECT `Ticket Status`, COUNT(*) AS ticket_count
FROM support_tickets_raw
GROUP BY `Ticket Status`
ORDER BY ticket_count DESC;

SELECT `Ticket Priority`, COUNT(*) AS ticket_count
FROM support_tickets_raw
GROUP BY `Ticket Priority`
ORDER BY ticket_count DESC;

SELECT `Ticket Channel`, COUNT(*) AS ticket_count
FROM support_tickets_raw
GROUP BY `Ticket Channel`
ORDER BY ticket_count DESC;

SELECT `Ticket Type`, COUNT(*) AS ticket_count
FROM support_tickets_raw
GROUP BY `Ticket Type`
ORDER BY ticket_count DESC;

SELECT `Customer Gender`, COUNT(*) AS customer_count
FROM support_tickets_raw
GROUP BY `Customer Gender`
ORDER BY customer_count DESC;

-- =========================================================
-- 5. Date and numeric field validation
-- =========================================================
-- These checks look for values that cannot be safely converted.
-- They are designed to return only problematic records.
SELECT `Date of Purchase`
FROM support_tickets_raw
WHERE `Date of Purchase` IS NOT NULL
  AND TRIM(`Date of Purchase`) <> ''
  AND STR_TO_DATE(TRIM(`Date of Purchase`), '%Y-%m-%d') IS NULL;

SELECT `First Response Time`
FROM support_tickets_raw
WHERE `First Response Time` IS NOT NULL
  AND TRIM(`First Response Time`) <> ''
  AND STR_TO_DATE(TRIM(`First Response Time`), '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT `Time to Resolution`
FROM support_tickets_raw
WHERE `Time to Resolution` IS NOT NULL
  AND TRIM(`Time to Resolution`) <> ''
  AND STR_TO_DATE(TRIM(`Time to Resolution`), '%Y-%m-%d %H:%i:%s') IS NULL;

SELECT `Customer Age`
FROM support_tickets_raw
WHERE `Customer Age` IS NULL
   OR TRIM(`Customer Age`) = ''
   OR TRIM(`Customer Age`) NOT REGEXP '^[0-9]+$';

SELECT `Customer Satisfaction Rating`
FROM support_tickets_raw
WHERE `Customer Satisfaction Rating` IS NOT NULL
  AND TRIM(`Customer Satisfaction Rating`) <> ''
  AND TRIM(`Customer Satisfaction Rating`) NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- =========================================================
-- 6. Create cleaned table
-- =========================================================
-- Creates the analysis-ready table used by exploration, KPI, and business question scripts.
-- The transformation standardizes names, casts dates and numbers, handles blanks,
-- and adds simple flags that make later queries easier to read.
DROP TABLE IF EXISTS support_tickets_cleaned;

CREATE TABLE support_tickets_cleaned AS
SELECT
    CAST(NULLIF(TRIM(`Ticket ID`), '') AS UNSIGNED) AS ticket_id,
    TRIM(`Customer Name`) AS customer_name,
    LOWER(TRIM(`Customer Email`)) AS customer_email,
    CAST(NULLIF(TRIM(`Customer Age`), '') AS UNSIGNED) AS customer_age,
    CASE
        WHEN TRIM(`Customer Gender`) IN ('Male', 'Female', 'Other') THEN TRIM(`Customer Gender`)
        ELSE 'Unknown'
    END AS customer_gender,
    TRIM(`Product Purchased`) AS product_purchased,
    STR_TO_DATE(NULLIF(TRIM(`Date of Purchase`), ''), '%Y-%m-%d') AS date_of_purchase,
    COALESCE(NULLIF(TRIM(`Ticket Type`), ''), 'Unknown') AS ticket_type,
    COALESCE(NULLIF(TRIM(`Ticket Subject`), ''), 'Unknown') AS ticket_subject,
    NULLIF(TRIM(`Ticket Description`), '') AS ticket_description,
    CASE
        WHEN TRIM(`Ticket Status`) IN ('Open', 'Closed', 'Pending Customer Response') THEN TRIM(`Ticket Status`)
        ELSE 'Unknown'
    END AS ticket_status,
    NULLIF(TRIM(`Resolution`), '') AS resolution,
    CASE
        WHEN TRIM(`Ticket Priority`) IN ('Low', 'Medium', 'High', 'Critical') THEN TRIM(`Ticket Priority`)
        ELSE 'Unknown'
    END AS ticket_priority,
    COALESCE(NULLIF(TRIM(`Ticket Channel`), ''), 'Unknown') AS ticket_channel,
    STR_TO_DATE(NULLIF(TRIM(`First Response Time`), ''), '%Y-%m-%d %H:%i:%s') AS first_response_at,
    STR_TO_DATE(NULLIF(TRIM(`Time to Resolution`), ''), '%Y-%m-%d %H:%i:%s') AS resolved_at,
    CAST(NULLIF(TRIM(`Customer Satisfaction Rating`), '') AS DECIMAL(3,1)) AS customer_satisfaction_rating,
    CASE
        WHEN STR_TO_DATE(NULLIF(TRIM(`First Response Time`), ''), '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(NULLIF(TRIM(`Time to Resolution`), ''), '%Y-%m-%d %H:%i:%s') IS NOT NULL
         AND STR_TO_DATE(NULLIF(TRIM(`Time to Resolution`), ''), '%Y-%m-%d %H:%i:%s')
             >= STR_TO_DATE(NULLIF(TRIM(`First Response Time`), ''), '%Y-%m-%d %H:%i:%s')
        THEN TIMESTAMPDIFF(
            HOUR,
            STR_TO_DATE(NULLIF(TRIM(`First Response Time`), ''), '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(NULLIF(TRIM(`Time to Resolution`), ''), '%Y-%m-%d %H:%i:%s')
        )
        ELSE NULL
    END AS resolution_time_hours,
    CASE
        WHEN TRIM(`Ticket Status`) = 'Closed' THEN 1
        ELSE 0
    END AS is_closed,
    CASE
        WHEN TRIM(`Ticket Status`) IN ('Open', 'Pending Customer Response') THEN 1
        ELSE 0
    END AS is_backlog,
    CASE
        WHEN CAST(NULLIF(TRIM(`Customer Satisfaction Rating`), '') AS DECIMAL(3,1)) IS NOT NULL
         AND CAST(NULLIF(TRIM(`Customer Satisfaction Rating`), '') AS DECIMAL(3,1)) < 3
        THEN 1
        ELSE 0
    END AS is_low_csat
FROM support_tickets_raw;

-- =========================================================
-- 7. Validate cleaned table
-- =========================================================
-- Final checks confirm that the cleaned table was created and that key fields
-- have usable values for the rest of the project.
SELECT COUNT(*) AS cleaned_total_rows
FROM support_tickets_cleaned;

SELECT
    SUM(CASE WHEN ticket_id IS NULL THEN 1 ELSE 0 END) AS missing_ticket_id,
    SUM(CASE WHEN ticket_status IS NULL OR ticket_status = 'Unknown' THEN 1 ELSE 0 END) AS unknown_ticket_status,
    SUM(CASE WHEN ticket_priority IS NULL OR ticket_priority = 'Unknown' THEN 1 ELSE 0 END) AS unknown_ticket_priority,
    SUM(CASE WHEN ticket_channel IS NULL OR ticket_channel = 'Unknown' THEN 1 ELSE 0 END) AS unknown_ticket_channel
FROM support_tickets_cleaned;

SELECT ticket_status, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_status
ORDER BY ticket_count DESC;

SELECT ticket_priority, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_priority
ORDER BY ticket_count DESC;
