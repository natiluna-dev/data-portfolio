-- ================================================================
-- Support Tickets Analysis
-- File: 00_import_raw_table.sql
-- Purpose:
-- Create the raw table used to import the Kaggle CSV file directly
-- into MySQL before cleaning and analysis.
-- ================================================================

-- This script prepares the raw staging table.
-- Keep the original CSV column names here so the import matches the source file.
-- The cleaned, analysis-ready field names are created later in 00_data_cleaning.sql.

CREATE DATABASE IF NOT EXISTS support_tickets_analysis;

USE support_tickets_analysis;

DROP TABLE IF EXISTS support_tickets_raw;

-- Raw table:
-- All fields are loaded as text first. This avoids import failures caused by
-- blanks, inconsistent date values, or numeric fields stored as strings.
CREATE TABLE support_tickets_raw (
    `Ticket ID` VARCHAR(20),
    `Customer Name` VARCHAR(150),
    `Customer Email` VARCHAR(255),
    `Customer Age` VARCHAR(10),
    `Customer Gender` VARCHAR(20),
    `Product Purchased` VARCHAR(150),
    `Date of Purchase` VARCHAR(20),
    `Ticket Type` VARCHAR(100),
    `Ticket Subject` VARCHAR(150),
    `Ticket Description` TEXT,
    `Ticket Status` VARCHAR(50),
    `Resolution` TEXT,
    `Ticket Priority` VARCHAR(20),
    `Ticket Channel` VARCHAR(50),
    `First Response Time` VARCHAR(30),
    `Time to Resolution` VARCHAR(30),
    `Customer Satisfaction Rating` VARCHAR(10)
) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Quick validation after import:
-- The expected dataset has 8,469 rows.
SELECT COUNT(*) AS total_rows
FROM support_tickets_raw;

-- Preview the imported rows before running the cleaning script.
SELECT *
FROM support_tickets_raw
LIMIT 5;
