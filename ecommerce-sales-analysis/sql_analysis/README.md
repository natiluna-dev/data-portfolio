# SQL Analysis

## Overview

This part of the project uses MySQL to clean, validate, and analyze selected tables from the Olist e-commerce dataset.

The SQL work focuses on:

- cleaning imported CSV data
- validating key fields
- calculating revenue metrics
- analyzing products, categories, and customers
- comparing results with the Pandas notebook

## Files

```text
00_data_cleaning.sql -> Data cleaning and validation checks
01_basic.sql         -> Core revenue and order analysis
02_intermediate.sql  -> AOV, top products, and category analysis
03_advanced.sql      -> Customer ranking, running totals, and monthly comparison
04_KPI_metrics.sql   -> Category concentration, segmentation, repeat purchase, and reconciliation
README.md            -> SQL summary
```

## Business Rules

- Only `delivered` orders are used for revenue metrics.
- `order_purchase_timestamp` is the main date used for monthly analysis.
- `customer_unique_id` is used for customer-level analysis because one customer can appear with more than one `customer_id`.
- Product revenue and freight revenue are kept separate.

Metric definitions:

```text
product_revenue = SUM(price)
freight_revenue = SUM(freight_value)
gross_order_value = SUM(price + freight_value)
product_aov = product_revenue / distinct delivered orders
gross_aov = gross_order_value / distinct delivered orders
```

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
| Top 10 category gross order value share | `62.38%` |
| Repeat customer share | `3.0%` |

## Analysis Included

### Revenue and Order Trends

Monthly gross order value and delivered order volume are calculated to show how sales change over time.

### Product and Category Performance

Products and categories are ranked by value and quantity sold.

### Customer Spend Segmentation

Customers are grouped into high, mid, and low spend segments using historical delivered spend.

### Repeat Purchase Indicators

Customers are classified as:

- `One-time`: one delivered order
- `Repeat`: more than one delivered order

### SQL and Pandas Comparison

The last query in `04_KPI_metrics.sql` produces the same core metrics shown in the Pandas notebook. This helps confirm that both workflows use the same filters and metric definitions.

## Data Quality Checks

| Check | Result | Decision |
| --- | ---: | --- |
| Duplicate `order_id` values | `0` | Use `order_id` as the order grain. |
| Duplicate `customer_id` values | `0` | Use `customer_id` for joins. |
| Repeated `customer_unique_id` values | `3,345` | Use `customer_unique_id` for customer-level analysis. |
| Duplicate `product_id` values | `0` | Use `product_id` for product joins. |
| Unmatched product IDs in `order_items` | `0` | No product transactions are lost in joins. |
| Product categories without English translation | `2` | Group missing translations as `Unknown`. |
| Products without category | `610` | Keep transactions and group as `Unknown`. |
| Negative price rows | `0` | No adjustment needed. |
| Negative freight rows | `0` | No adjustment needed. |

## Skills Demonstrated

- data cleaning after CSV import
- data validation
- joins across relational tables
- aggregations and KPI calculation
- CTEs
- window functions
- ranking
- monthly trend analysis
