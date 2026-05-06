-- ================================================================
-- Support Tickets Analysis
-- File: 02_kpis.sql
-- Purpose:
-- Calculate the main KPIs supported by the ticket dataset.
-- ================================================================

-- Base table:
-- support_tickets_cleaned
--
-- Business definitions:
-- closed tickets = ticket_status = 'Closed'
-- backlog tickets = ticket_status IN ('Open', 'Pending Customer Response')
-- low CSAT = customer_satisfaction_rating < 3
-- resolution time = hours between first_response_at and resolved_at
--                   when resolved_at is not earlier than first_response_at

USE support_tickets_analysis;

-- =========================================================
-- 1. Total tickets
-- =========================================================
-- Overall ticket volume in the cleaned dataset.
SELECT
    COUNT(*) AS total_tickets
FROM support_tickets_cleaned;

-- =========================================================
-- 2. Closed tickets, backlog tickets, and rates
-- =========================================================
-- Main operational status split.
-- Percentages are calculated against total tickets.
SELECT
    COUNT(*) AS total_tickets,
    SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets,
    ROUND(
        100.0 * SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS closed_ticket_rate_pct,
    SUM(CASE WHEN ticket_status IN ('Open', 'Pending Customer Response') THEN 1 ELSE 0 END) AS backlog_tickets,
    ROUND(
        100.0 * SUM(CASE WHEN ticket_status IN ('Open', 'Pending Customer Response') THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS backlog_rate_pct
FROM support_tickets_cleaned;

-- =========================================================
-- 3. Average resolution time
-- =========================================================
-- Average resolution time for tickets where both timestamps exist
-- and the resolution timestamp is not earlier than the first response timestamp.
-- This is not first-response delay because the dataset has no ticket creation timestamp.
SELECT
    ROUND(AVG(resolution_time_hours), 2) AS avg_resolution_time_hours
FROM support_tickets_cleaned
WHERE first_response_at IS NOT NULL
  AND resolved_at IS NOT NULL;

-- =========================================================
-- 4. Average customer satisfaction rating
-- =========================================================
-- Average CSAT across rated tickets only.
SELECT
    ROUND(AVG(customer_satisfaction_rating), 2) AS avg_csat_rating
FROM support_tickets_cleaned
WHERE customer_satisfaction_rating IS NOT NULL;

-- =========================================================
-- 5. Low CSAT percentage among rated closed tickets
-- =========================================================
-- Measures the share of poor satisfaction ratings among closed tickets with a CSAT value.
SELECT
    COUNT(*) AS rated_closed_tickets,
    SUM(CASE WHEN customer_satisfaction_rating < 3 THEN 1 ELSE 0 END) AS low_csat_tickets,
    ROUND(
        100.0 * SUM(CASE WHEN customer_satisfaction_rating < 3 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS low_csat_rate_pct
FROM support_tickets_cleaned
WHERE ticket_status = 'Closed'
  AND customer_satisfaction_rating IS NOT NULL;

-- =========================================================
-- 6. Compact KPI summary
-- =========================================================
-- Produces a single metric/value table that is easy to export and connect to Excel.
WITH kpi_base AS (
    SELECT
        COUNT(*) AS total_tickets,
        SUM(CASE WHEN ticket_status = 'Closed' THEN 1 ELSE 0 END) AS closed_tickets,
        SUM(CASE WHEN ticket_status IN ('Open', 'Pending Customer Response') THEN 1 ELSE 0 END) AS backlog_tickets,
        AVG(CASE WHEN resolution_time_hours IS NOT NULL THEN resolution_time_hours END) AS avg_resolution_time_hours,
        AVG(CASE WHEN customer_satisfaction_rating IS NOT NULL THEN customer_satisfaction_rating END) AS avg_csat_rating,
        SUM(
            CASE
                WHEN ticket_status = 'Closed'
                 AND customer_satisfaction_rating IS NOT NULL
                 AND customer_satisfaction_rating < 3
                THEN 1
                ELSE 0
            END
        ) AS low_csat_tickets,
        SUM(
            CASE
                WHEN ticket_status = 'Closed'
                 AND customer_satisfaction_rating IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) AS rated_closed_tickets
    FROM support_tickets_cleaned
)
SELECT 'total_tickets' AS metric_name, CAST(total_tickets AS DECIMAL(12,2)) AS metric_value
FROM kpi_base
UNION ALL
SELECT 'closed_tickets', CAST(closed_tickets AS DECIMAL(12,2))
FROM kpi_base
UNION ALL
SELECT 'backlog_tickets', CAST(backlog_tickets AS DECIMAL(12,2))
FROM kpi_base
UNION ALL
SELECT 'closed_ticket_rate_pct', ROUND(100.0 * closed_tickets / NULLIF(total_tickets, 0), 2)
FROM kpi_base
UNION ALL
SELECT 'backlog_rate_pct', ROUND(100.0 * backlog_tickets / NULLIF(total_tickets, 0), 2)
FROM kpi_base
UNION ALL
SELECT 'avg_resolution_time_hours', ROUND(avg_resolution_time_hours, 2)
FROM kpi_base
UNION ALL
SELECT 'avg_csat_rating', ROUND(avg_csat_rating, 2)
FROM kpi_base
UNION ALL
SELECT 'low_csat_rate_pct',
       ROUND(100.0 * low_csat_tickets / NULLIF(rated_closed_tickets, 0), 2)
FROM kpi_base;
