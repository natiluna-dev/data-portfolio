# E-commerce Sales Analysis with Pandas

## Overview

This part of the project uses Python and Pandas to explore sales trends, customer behavior, and product performance.

The notebook follows a simple analysis flow:

- load the data
- validate key fields
- clean and prepare the tables
- create business metrics
- build charts to explain the results

## Questions Answered

- How does gross order value change over time?
- Which categories generate the most gross order value?
- How is customer spending distributed?
- Who are the top-spending customers?
- Which products sell the most units?

## Tools

- Python
- Pandas
- Matplotlib
- Jupyter Notebook

## Data Preparation

Main preparation steps:

- convert imported date columns to datetime
- check duplicate keys
- check missing values
- keep only delivered orders for revenue analysis
- create derived metrics
- merge the tables used for analysis

## Main Analysis

### Monthly Gross Order Value Trend

Shows how total gross order value changes over time.

### Gross Order Value by Category

Shows which categories generate the most value.

### Customer Spend Distribution

Shows how customer spend is spread across the dataset.

### Top Customers

Ranks customers by total gross spend.

### Top Products

Ranks products by quantity sold.

## Visualizations

The notebook exports the main charts to `pandas_analysis/outputs/` so they can be viewed directly on GitHub.

### Monthly Gross Order Value

![Monthly gross order value trend](outputs/monthly_gross_order_value_trend.png)

### Top 10 Categories by Gross Order Value

![Top 10 categories by gross order value](outputs/top_10_categories_by_gross_order_value.png)

### Customer Gross Spend Distribution

![Customer gross spend distribution](outputs/customer_gross_spend_distribution.png)

### Top 10 Customers by Gross Spend

![Top 10 customers by gross spend](outputs/top_10_customers_by_gross_spend.png)

### Top 10 Products by Quantity Sold

![Top 10 products by quantity sold](outputs/top_10_products_by_quantity_sold.png)

## Key Results

- Gross order value: `15,419,773.75`
- Product revenue: `13,221,498.11`
- Freight revenue: `2,198,275.64`
- Gross AOV: `159.83`
- Top 10 categories share: `62.38%`
- Repeat customer share: `3.0%`

## Data Quality Notes

The notebook includes validation checks to support the analysis:

- `0` duplicate `order_id` values
- `0` duplicate `customer_id` values
- `3,345` repeated `customer_unique_id` values
- `0` unmatched product IDs in `order_items`
- `2` product categories without English translation
- `610` products without category
- `0` negative price rows
- `0` negative freight rows

The notebook also includes a comparison table to confirm that the main SQL and Pandas metrics match.

## Files Included

```text
01_pandas_analysis.ipynb -> Full notebook analysis
outputs/                  -> Exported chart images
README.md                 -> Notebook summary
```

## Skills Demonstrated

- data cleaning
- exploratory data analysis
- data validation
- feature engineering
- KPI analysis
- data visualization
