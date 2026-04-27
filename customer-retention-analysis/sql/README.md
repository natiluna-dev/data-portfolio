# SQL Analysis

## Overview

This folder contains the SQL analysis used in the customer retention project.

Its purpose is to clean the raw churn dataset, create a reliable table for analysis, calculate key KPIs, and answer business questions related to customer churn.

## Main Analytical Table

The main table used across the analysis is `customer_churn_cleaned`.

This table standardizes the original dataset so the rest of the queries can use consistent field names, categories, and numeric values.

## Business Definitions

- tenure buckets:
  - `0-12 months`
  - `13-24 months`
  - `25-48 months`
  - `49+ months`
- `No` and `No internet service` are kept separate when service interpretation matters
- revenue at risk is the sum of `monthly_charges` for churned customers

## Files

```text
00_data_cleaning.sql        -> Cleans and validates the dataset
01_exploratory_analysis.sql -> Explores customer distribution and service mix
02_kpi_analysis.sql         -> Calculates churn, retention, and main KPI cuts
03_advanced_analysis.sql    -> Builds deeper segment analysis
04_business_questions.sql   -> Answers business-facing questions with SQL
README.md                   -> SQL summary
```

## Analysis Included

- data cleaning and validation
- churn and retention KPI calculation
- churn analysis by contract type
- churn analysis by tenure bucket
- churn analysis by payment method
- revenue-at-risk analysis
- risk segmentation

## Key Results

| Metric | Result |
| --- | ---: |
| Total customers | `7,043` |
| Churned customers | `1,869` |
| Retained customers | `5,174` |
| Churn rate | `26.54%` |
| Retention rate | `73.46%` |

## Main Findings

- Month-to-month contracts have the highest churn.
- Customers with `0-12 months` of tenure are the most likely to churn.
- `Electronic check` has the highest churn among payment methods.
- The highest-risk segments combine short tenure, flexible contracts, and missing support or security services.

In simple terms, the SQL analysis helps explain who is leaving, where churn is highest, and which customer groups matter most for retention.

## Skills Demonstrated

- SQL data cleaning
- data validation
- KPI calculation
- exploratory analysis
- churn segmentation
- business-oriented analysis
