# Customer Retention Analysis

## Overview

This project analyzes customer churn in a telecom company using SQL and Tableau.

The goal is to understand which customer groups are more likely to leave, which factors are linked to churn, and which groups put more monthly revenue at risk.

This project focuses on:

- cleaning and validating raw customer data
- building a clean table for analysis
- calculating churn and retention KPIs
- comparing churn across key customer groups
- presenting the results in Tableau

## Business Questions

This project is designed to answer questions such as:

- What is the overall churn rate?
- Which contract types have the highest churn?
- Are newer customers more likely to leave?
- Which payment methods are associated with higher churn?
- Which customer segments represent the highest revenue risk?

## Dataset

The project uses the Telco Customer Churn dataset.

Each row represents one customer and includes:

- demographic information
- contract details
- subscribed services
- tenure
- monthly and total charges
- churn status

The main target variable is `churn`.

## Tools Used

- SQL
- Tableau

## Analytical Approach

The work is organized in two parts:

- SQL for data cleaning, validation, KPI calculation, and churn analysis
- Tableau for dashboard design and presentation

The SQL analysis creates a cleaned table called `customer_churn_cleaned`, which is then used to create the CSV files behind the Tableau dashboard.

## Key Metrics

- Total customers: `7,043`
- Churned customers: `1,869`
- Retained customers: `5,174`
- Churn rate: `26.54%`
- Retention rate: `73.46%`
- Revenue at risk: `139130.85`

In this project, `revenue at risk` means the monthly revenue linked to customers who churned.

## Key Findings

- Month-to-month contracts have the highest churn rate.
- Customers in the first `0-12 months` have the highest churn rate.
- `Electronic check` is the payment method with the highest churn.
- The highest-risk segments combine short tenure, month-to-month contracts, and lack of support or security services.

## Repository Structure

```text
customer-retention-analysis/
|-- README.md
|-- data/
|   |-- raw/
|   |   `-- WA_Fn-UseC_-Telco-Customer-Churn.csv
|   `-- exports/
|       |-- customer_churn_cleaned.csv
|       |-- kpi_summary.csv
|       |-- churn_by_contract.csv
|       |-- churn_by_tenure_bucket.csv
|       |-- churn_by_payment_method.csv
|       `-- risk_segments.csv
|-- sql/
|   |-- 00_data_cleaning.sql
|   |-- 01_exploratory_analysis.sql
|   |-- 02_kpi_analysis.sql
|   |-- 03_advanced_analysis.sql
|   |-- 04_business_questions.sql
|   `-- README.md
`-- tableau/
    |-- README.md
    |-- customer_churn_dashboard.png
    `-- customer_churn_dashboard.pdf
```

## SQL Analysis

The SQL work includes:

- data cleaning
- data quality checks
- KPI calculation
- churn breakdowns by contract, tenure, and payment method
- revenue-at-risk analysis
- churn segmentation

See [sql/README.md](sql/README.md) for more details.

## Tableau Dashboard

The Tableau part of the project summarizes the main findings in a one-page dashboard focused on:

- KPI cards
- churn by contract
- churn by tenure bucket
- churn by payment method
- top risk segments

The repository includes:

- a PNG preview of the final dashboard: `tableau/customer_churn_dashboard.png`
- a PDF export for sharing: `tableau/customer_churn_dashboard.pdf`
- the live dashboard on Tableau Public: [Customer Churn Dashboard](https://public.tableau.com/views/customer_churn_dashboard_17773192736060/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

See [tableau/README.md](tableau/README.md) for more details.

## Skills Demonstrated

- data cleaning in SQL
- exploratory analysis
- KPI calculation
- churn analysis
- customer segmentation
- dashboard design in Tableau

## Limitations

- This project is descriptive, not predictive.
- No machine learning model is included.
- The dataset is static and should not be interpreted as current business performance.
