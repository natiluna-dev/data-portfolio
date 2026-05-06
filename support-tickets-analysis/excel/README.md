# Excel Dashboard

## Overview

This folder contains the final Excel workbook for the support tickets project.

Main file:

- `support_tickets_dashboard.xlsx`

## Workbook Purpose

The Excel workbook is the presentation layer of the project.

It combines two complementary pieces:

- SQL output sheets that document the business summaries generated from the analysis.
- An interactive Excel dashboard built with pivot tables, charts, and slicers.

The workbook uses the exported SQL result files from `../data/exports/` and presents:

- KPI cards
- ticket mix by category
- priority breakdown
- channel comparison
- customer satisfaction summary
- monthly ticket trend

## Workbook Structure

- `Dashboard`
- `Tickets Data`
- `KPI Summary`
- `By_Category`
- `By_Priority`
- `By_Channel`
- `CSAT_Summary`
- `Monthly_Trend`
- `Pivot tables` hidden helper sheet

The `Dashboard` sheet is the final user-facing view. It uses pivot charts and slicers so the analysis can be filtered by ticket type, status, and priority.

The SQL output sheets are kept visible because they show the reproducible summaries behind the dashboard. They are analytical support, not separate dashboards.

## Recommended Build Flow

1. Run the final SQL files in `../sql/`.
2. Export the final result sets as CSV files into `data/exports/`.
3. Load the cleaned ticket table and SQL exports into Excel.
4. Build or refresh the pivot tables and charts from `Tickets Data`.
5. Use slicers on the final dashboard for interactive filtering.
6. Keep pivot tables as hidden helper content.
