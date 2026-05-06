# Support Tickets Analysis

## Overview

This project analyzes customer support tickets with SQL and Excel.

The goal is to understand ticket volume, status mix, resolution behavior, channel distribution, and customer satisfaction in a simple business-friendly way.

This project demonstrates a practical support operations analysis using SQL and Excel.

## Business Questions

- How many tickets are currently open, pending, or closed?
- Which ticket types generate the most volume?
- Which priorities accumulate more unresolved work?
- Which channels receive the most tickets?
- Which products generate more support demand?
- How does customer satisfaction vary by ticket type and priority?

## Dataset

The raw data comes from the Kaggle dataset [Customer Support Ticket Dataset](https://www.kaggle.com/datasets/suraj520/customer-support-ticket-dataset).

The raw dataset is not committed to this repository. Download it from Kaggle and place the CSV locally under `data/raw/` before running the import workflow.

The dataset contains `8,469` support tickets and includes:

- ticket identifiers
- customer demographic fields
- purchased product
- ticket type
- ticket status
- ticket priority
- ticket channel
- first response timestamp
- resolution timestamp
- customer satisfaction rating

## Tools

- MySQL
- SQL
- Excel

## Analytical Approach

The project is organized in two parts:

- SQL is used for cleaning, validation, KPI calculation, and business question analysis.
- Excel is used to present the SQL outputs and build an interactive final dashboard with pivot charts and slicers.

The SQL analysis creates a cleaned table called `support_tickets_cleaned`.

SQL remains the analytical layer of the project. The Excel workbook is the presentation layer: it keeps the SQL export tabs visible for transparency and uses pivot tables from the cleaned ticket data to make the final dashboard interactive.

## Key Findings

- The dataset contains `8,469` support tickets.
- `32.70%` of tickets are closed, while `67.30%` remain in backlog.
- `Refund request` and `Technical issue` are the highest-volume ticket types.
- Average customer satisfaction is `2.99 / 5`, showing a neutral-to-low satisfaction level.
- `39.80%` of rated closed tickets have low CSAT, defined as a rating below `3`.
- Average valid resolution time is `7.11` hours after excluding records where the resolution timestamp is earlier than the first response timestamp.

## Important Dataset Limitations

This dataset is useful for support operations analysis, but it does not include:

- assigned agent or support owner
- SLA target fields
- ticket creation timestamp

Because of that:

- agent performance is out of scope
- true SLA compliance cannot be calculated
- monthly trends are based on `first_response_at` activity rather than ticket creation date
- resolution time is measured from first response timestamp to resolution timestamp when both exist and the resolution timestamp is not earlier than the first response timestamp
- records with negative resolution time are treated as invalid for resolution-time metrics

## Files

```text
support-tickets-analysis/
├── README.md
├── data/
│   ├── raw/
│   │   └── customer_support_tickets.csv
│   └── exports/
│       ├── tickets_cleaned.csv
│       ├── kpi_summary.csv
│       ├── tickets_by_category.csv
│       ├── tickets_by_priority.csv
│       ├── tickets_by_channel.csv
│       ├── satisfaction_summary.csv
│       └── monthly_ticket_trend.csv
├── sql/
│   ├── 00_import_raw_table.sql
│   ├── 00_data_cleaning.sql
│   ├── 01_exploration.sql
│   ├── 02_kpis.sql
│   ├── 03_business_questions.sql
│   └── README.md
└── excel/
    ├── README.md
    └── support_tickets_dashboard.xlsx
```

## Main Outputs

- cleaned ticket table
- KPI summary export
- breakdowns by category, priority, and channel
- customer satisfaction summary
- monthly response trend
- interactive Excel dashboard workbook

## Suggested Workflow

1. Create the raw MySQL table with `sql/00_import_raw_table.sql`.
2. Import the Kaggle CSV into `support_tickets_raw`.
3. Run the SQL files in order.
4. Export the result tables to the `data/exports/` folder.
5. Use those exports in `excel/support_tickets_dashboard.xlsx`.

## Importing The CSV Into MySQL

Use [00_import_raw_table.sql](sql/00_import_raw_table.sql) to create the raw staging table.

The project was built using MySQL Workbench:

1. Open your schema.
2. Right click `Tables`.
3. Choose `Table Data Import Wizard`.
4. Select `data/raw/customer_support_tickets.csv`.
5. Import into the existing table `support_tickets_raw`.

If the direct CSV import fails, create a local SQL insert file from the downloaded CSV and run it after creating `support_tickets_raw`.

Then validate the import with:

```sql
SELECT COUNT(*) AS total_rows FROM support_tickets_raw;
SELECT * FROM support_tickets_raw LIMIT 5;
```

## Skills Demonstrated

- SQL data cleaning
- validation checks
- KPI calculation
- exploratory analysis
- business-oriented summarization
- Excel dashboard preparation
