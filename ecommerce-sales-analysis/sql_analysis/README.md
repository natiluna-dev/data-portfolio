# SQL Analysis

## Overview

This part of the project uses MySQL to clean, validate, and analyze selected tables from the Brazilian Olist e-commerce dataset.

The SQL work focuses on:

- data type cleanup after CSV import
- data quality validation
- delivered-order revenue metrics
- product, category, and customer analysis
- window functions for ranking, running totals, and month-over-month comparison
- reconciliation with the Pandas notebook

## Files

```text
00_data_cleaning.sql -> Data type cleanup, key validation, and data quality checks
01_basic.sql         -> Core delivered-order metrics and monthly order volume
02_intermediate.sql  -> AOV, top products, and category gross order value
03_advanced.sql      -> Category contribution, customer ranking, running totals, and MoM growth
04_KPI_metrics.sql   -> KPI-style queries, segmentation, repeat purchase indicators, and reconciliation
README.md            -> SQL project documentation
```

## Business Rules

- Only `delivered` orders are used for revenue and KPI calculations.
- `order_purchase_timestamp` is used as the main business date for monthly analysis.
- `customer_unique_id` is used for customer-level analysis because one real customer can have multiple `customer_id` values.
- Product revenue and freight revenue are separated to avoid overstating product sales.

Metric definitions:

```text
product_revenue = SUM(price)
freight_revenue = SUM(freight_value)
gross_order_value = SUM(price + freight_value)
product_aov = product_revenue / distinct delivered orders
gross_aov = gross_order_value / distinct delivered orders
```

## Data Quality Checks

| Check | Result | Decision |
| --- | ---: | --- |
| Duplicate `order_id` values | `0` | Use `order_id` as the order grain. |
| Duplicate `customer_id` values | `0` | Use `customer_id` for joins. |
| Repeated `customer_unique_id` values | `3,345` | Use `customer_unique_id` for customer-level analysis. |
| Duplicate `product_id` values | `0` | Use `product_id` for product/category joins. |
| Unmatched product IDs in `order_items` | `0` | No product transactions are lost in product joins. |
| Product categories without English translation | `2` | Group missing translations as `Unknown`. |
| Products without category | `610` | Keep transactions and group as `Unknown`. |
| Negative price rows | `0` | No adjustment needed. |
| Negative freight rows | `0` | No adjustment needed. |

## Key Results

| Metric | Result |
| --- | ---: |
| Delivered item rows | `110,197` |
| Delivered orders | `96,478` |
| Product revenue | `13,221,498.11` |
| Freight revenue | `2,198,275.64` |
| Gross order value | `15,419,773.75` |
| Product AOV | `137.04` |
| Gross AOV | `159.83` |
| Top 5 category gross order value share | `39.25%` |
| Top 10 category gross order value share | `62.38%` |
| One-time customer share | `97.0%` |
| Repeat customer share | `3.0%` |

## Analysis Performed

### Revenue And Order Trends

Monthly gross order value and delivered order volume are calculated to understand business performance over time. Running totals and month-over-month growth use SQL window functions.

### Product And Category Performance

Products and categories are ranked by gross order value and quantity sold. Category contribution is calculated as a percentage of total delivered gross order value.

### Customer Spend Segmentation

Customers are grouped into high, mid, and low historical spend segments using `NTILE(3)` over delivered gross spend.

This is historical spend segmentation, not a predictive lifetime value model. It is used to understand customer value distribution in the available dataset.

### Repeat Purchase Indicators

Customers are classified as:

- `One-time`: one delivered order
- `Repeat`: more than one delivered order

This supports a basic retention read: only `3.0%` of customers placed more than one delivered order.

### Category Growth

Category-level month-over-month growth is calculated to identify potential areas for further investigation.

Growth percentages should be interpreted carefully for low-volume categories because small absolute revenue changes can create large percentage changes.

## SQL/Pandas Reconciliation

Query 19 in `04_KPI_metrics.sql` produces the same core metrics shown in the Pandas notebook:

- delivered item rows
- delivered orders
- product revenue
- freight revenue
- gross order value
- product AOV
- gross AOV

This confirms that the SQL and Pandas workflows use consistent joins, filters, and metric definitions.

## Skills Demonstrated

- Data cleaning after CSV import
- Data quality validation
- Joins across relational tables
- Aggregations and KPI calculation
- CTEs
- Window functions
- Ranking
- Month-over-month comparison
- Business rule documentation
- SQL/Pandas metric reconciliation
