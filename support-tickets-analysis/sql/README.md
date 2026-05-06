# SQL Analysis

## Overview

This folder contains the final executable SQL scripts used in the support tickets analysis project.

The SQL flow imports the raw CSV structure, validates and cleans the data, explores the cleaned table, calculates KPIs, and answers business-facing questions used for exports and the Excel dashboard.

## Main Analytical Table

The main table used across the analysis is `support_tickets_cleaned`.

This table is created in `00_data_cleaning.sql` from the raw staging table `support_tickets_raw`.

The file `data/exports/tickets_cleaned.csv` is the exported CSV version of the full `support_tickets_cleaned` table.

## Business Definitions

- closed tickets: `ticket_status = 'Closed'`
- backlog tickets: `ticket_status IN ('Open', 'Pending Customer Response')`
- low CSAT: `customer_satisfaction_rating < 3`
- resolution time: hours between `first_response_at` and `resolved_at` when both timestamps exist and `resolved_at >= first_response_at`
- monthly trend: based on `first_response_at`, because the dataset does not include a ticket creation timestamp

## Files

```text
00_import_raw_table.sql     -> Creates the raw MySQL table used for CSV import
00_data_cleaning.sql        -> Validates raw data and creates support_tickets_cleaned
01_exploration.sql          -> Explores cleaned data quality and key distributions
02_kpis.sql                 -> Calculates operational and satisfaction KPIs
03_business_questions.sql   -> Answers business-facing questions for dashboard exports
README.md                   -> SQL summary
```

## Recommended Execution Order

1. Run `00_import_raw_table.sql`.
2. Import `data/raw/customer_support_tickets.csv` into `support_tickets_raw`.
3. Run `00_data_cleaning.sql`.
4. Run `01_exploration.sql`.
5. Run `02_kpis.sql`.
6. Run `03_business_questions.sql`.

## Analysis Included

- raw data import structure
- data validation checks
- cleaned analytical table creation
- ticket status, priority, channel, product, and category exploration
- closed ticket and backlog KPIs
- resolution time and CSAT KPIs
- export-ready summaries for Excel
