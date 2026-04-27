# Tableau Dashboard

## Overview

This folder contains the Tableau dashboard files for the customer retention project.

The goal of the dashboard is to present the main churn findings from the SQL analysis in a clear and simple way.

## Questions Answered

- What is the current churn level?
- Which customer groups are most exposed?
- Where should retention efforts start first?

## Dashboard Structure

The one-page dashboard includes five views:

1. KPI cards
2. Churn rate by contract
3. Churn rate by tenure bucket
4. Churn rate by payment method
5. Top risk segments by churn rate and revenue at risk

## Data Sources

The dashboard is based on CSV exports prepared from the SQL analysis:

- `kpi_summary.csv`
- `churn_by_contract.csv`
- `churn_by_tenure_bucket.csv`
- `churn_by_payment_method.csv`
- `risk_segments.csv`

These files keep the dashboard aligned with the SQL analysis.

## Files

- `customer_churn_dashboard.png`: preview image for the repository
- `customer_churn_dashboard.pdf`: export version for easy sharing
- `customer_churn_dashboard.twb`: Tableau workbook

## Live Dashboard

- [Customer Churn Dashboard](https://public.tableau.com/views/customer_churn_dashboard_17773192736060/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)

## Main Message

- The dashboard shows the overall churn level.
- It highlights the customer groups with the highest churn.
- It helps identify where retention action should start first.

## Design Approach

- KPI cards for the overall summary
- bar charts for the main comparisons
- a ranked segment view for the highest-risk groups

The dashboard is intentionally simple so the main findings are easy to understand.

## Skills Demonstrated

- dashboard planning
- visual communication of analysis
- SQL-to-Tableau workflow
- KPI presentation
- business-focused reporting
