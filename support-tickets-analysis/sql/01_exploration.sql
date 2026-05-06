-- ================================================================
-- Support Tickets Analysis
-- File: 01_exploration.sql
-- Purpose:
-- Explore the cleaned table, validate distributions, and inspect
-- the fields used later for KPI and dashboard analysis.
-- ================================================================

-- Base table:
-- support_tickets_cleaned
--
-- This script is descriptive. It checks whether the cleaned table is ready for
-- analysis and surfaces the main ticket distributions used in later outputs.

USE support_tickets_analysis;

-- =========================================================
-- 1. Total cleaned rows
-- =========================================================
-- Confirms the final row count after cleaning.
SELECT COUNT(*) AS total_cleaned_rows
FROM support_tickets_cleaned;

-- =========================================================
-- 2. Null checks in key analysis fields
-- =========================================================
-- Measures missingness in fields used for volume, status, channel, product,
-- resolution time, and customer satisfaction analysis.
SELECT
    SUM(CASE WHEN product_purchased IS NULL OR product_purchased = '' THEN 1 ELSE 0 END) AS missing_product_purchased,
    SUM(CASE WHEN ticket_type IS NULL OR ticket_type = '' THEN 1 ELSE 0 END) AS missing_ticket_type,
    SUM(CASE WHEN ticket_status IS NULL OR ticket_status = '' THEN 1 ELSE 0 END) AS missing_ticket_status,
    SUM(CASE WHEN ticket_priority IS NULL OR ticket_priority = '' THEN 1 ELSE 0 END) AS missing_ticket_priority,
    SUM(CASE WHEN ticket_channel IS NULL OR ticket_channel = '' THEN 1 ELSE 0 END) AS missing_ticket_channel,
    SUM(CASE WHEN first_response_at IS NULL THEN 1 ELSE 0 END) AS missing_first_response_at,
    SUM(CASE WHEN resolved_at IS NULL THEN 1 ELSE 0 END) AS missing_resolved_at,
    SUM(CASE WHEN customer_satisfaction_rating IS NULL THEN 1 ELSE 0 END) AS missing_customer_satisfaction_rating
FROM support_tickets_cleaned;

-- =========================================================
-- 3. Duplicate ticket ID validation
-- =========================================================
-- Returns duplicated ticket IDs if any exist in the cleaned table.
SELECT
    ticket_id,
    COUNT(*) AS ticket_id_count
FROM support_tickets_cleaned
GROUP BY ticket_id
HAVING COUNT(*) > 1;

-- =========================================================
-- 4. Main categorical distributions
-- =========================================================
-- Reviews the main business dimensions before building KPIs and exports.
SELECT ticket_status, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_status
ORDER BY ticket_count DESC;

SELECT ticket_priority, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_priority
ORDER BY ticket_count DESC;

SELECT ticket_channel, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_channel
ORDER BY ticket_count DESC;

SELECT ticket_type, COUNT(*) AS ticket_count
FROM support_tickets_cleaned
GROUP BY ticket_type
ORDER BY ticket_count DESC;

SELECT customer_gender, COUNT(*) AS customer_count
FROM support_tickets_cleaned
GROUP BY customer_gender
ORDER BY customer_count DESC;

-- =========================================================
-- 5. Top products by ticket volume
-- =========================================================
-- Identifies the products generating the highest support demand.
SELECT
    product_purchased,
    COUNT(*) AS total_tickets
FROM support_tickets_cleaned
GROUP BY product_purchased
ORDER BY total_tickets DESC, product_purchased
LIMIT 10;

-- =========================================================
-- 6. Closed tickets with and without CSAT
-- =========================================================
-- Checks how much closed-ticket satisfaction data is available.
-- This matters because CSAT metrics should only be calculated from rated tickets.
SELECT
    CASE
        WHEN customer_satisfaction_rating IS NULL THEN 'Closed without rating'
        ELSE 'Closed with rating'
    END AS csat_status,
    COUNT(*) AS total_tickets
FROM support_tickets_cleaned
WHERE ticket_status = 'Closed'
GROUP BY csat_status
ORDER BY total_tickets DESC;

-- =========================================================
-- 7. Resolution time distribution
-- =========================================================
-- Summarizes the resolution-time field used later in KPI and channel analysis.
-- Only closed tickets with valid response and resolution timestamps are included.
-- Records where resolution is earlier than first response are treated as missing
-- by the cleaning step.
SELECT
    COUNT(*) AS closed_tickets_with_resolution_time,
    ROUND(AVG(resolution_time_hours), 2) AS avg_resolution_time_hours,
    MIN(resolution_time_hours) AS min_resolution_time_hours,
    MAX(resolution_time_hours) AS max_resolution_time_hours
FROM support_tickets_cleaned
WHERE ticket_status = 'Closed'
  AND resolution_time_hours IS NOT NULL;
