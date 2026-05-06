-- ================================================================
-- Support Tickets Analysis
-- File: 03_business_questions.sql
-- Purpose:
-- Answer business-facing support ticket questions and generate
-- export-ready summary tables for the Excel dashboard.
-- ================================================================

-- Base table:
-- support_tickets_cleaned
--
-- These queries produce stakeholder-friendly summaries that can be exported
-- into CSV files and used in the Excel dashboard.

USE support_tickets_analysis;

-- =========================================================
-- 1. Ticket volume by category
-- =========================================================
-- Shows which ticket types generate the most demand and how often they are closed.
SELECT
    ticket_type,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets,
    ROUND(
        100.0 * SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS closed_rate_pct
FROM support_tickets_cleaned
GROUP BY ticket_type
ORDER BY total_tickets DESC, ticket_type;

-- =========================================================
-- 2. Ticket volume by priority
-- =========================================================
-- Compares backlog volume across priority levels.
-- The ORDER BY keeps priorities in business severity order instead of alphabetical order.
SELECT
    ticket_priority,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status IN ('Open', 'Pending Customer Response') THEN 1 ELSE 0 END) AS backlog_tickets,
    ROUND(
        100.0 * SUM(CASE WHEN ticket_status IN ('Open', 'Pending Customer Response') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS backlog_rate_pct
FROM support_tickets_cleaned
GROUP BY ticket_priority
ORDER BY
    CASE ticket_priority
        WHEN 'Critical' THEN 1
        WHEN 'High' THEN 2
        WHEN 'Medium' THEN 3
        WHEN 'Low' THEN 4
        ELSE 5
    END;

-- =========================================================
-- 3. Ticket volume by channel
-- =========================================================
-- Compares channels by volume, closed tickets, and average valid resolution time.
SELECT
    ticket_channel,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets,
    ROUND(AVG(resolution_time_hours), 2) AS avg_resolution_time_hours
FROM support_tickets_cleaned
GROUP BY ticket_channel
ORDER BY total_tickets DESC, ticket_channel;

-- =========================================================
-- 4. Top 10 products by ticket volume
-- =========================================================
-- Identifies products creating the most support demand.
SELECT
    product_purchased,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets
FROM support_tickets_cleaned
GROUP BY product_purchased
ORDER BY total_tickets DESC, product_purchased
LIMIT 10;

-- =========================================================
-- 5. Monthly ticket trend by first response month
-- =========================================================
-- Builds a monthly trend using first_response_at.
-- The dataset does not include ticket creation timestamp, so this is a response activity trend.
SELECT
    DATE_FORMAT(first_response_at, '%Y-%m-01') AS response_month,
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets,
    ROUND(AVG(customer_satisfaction_rating), 2) AS avg_csat_rating
FROM support_tickets_cleaned
WHERE first_response_at IS NOT NULL
GROUP BY DATE_FORMAT(first_response_at, '%Y-%m-01')
ORDER BY response_month;

-- =========================================================
-- 6. Customer satisfaction summary by ticket type
-- =========================================================
-- Compares rated tickets by ticket type and ranks lower CSAT first to surface pain points.
SELECT
    ticket_type,
    COUNT(*) AS rated_tickets,
    ROUND(AVG(customer_satisfaction_rating), 2) AS avg_csat_rating,
    ROUND(
        100.0 * SUM(CASE WHEN customer_satisfaction_rating < 3 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS low_csat_rate_pct
FROM support_tickets_cleaned
WHERE customer_satisfaction_rating IS NOT NULL
GROUP BY ticket_type
ORDER BY avg_csat_rating ASC, rated_tickets DESC;
