# QA Bug Analytics - SQL Project

## Overview
This project simulates a real-world QA analytics environment using MySQL.

It analyzes bug tracking data across projects, developers, and sprints to extract actionable insights that a QA Lead or Engineering Manager could use to improve delivery and product quality.

---

## Business Context
In fast-paced development environments, teams need visibility into:
- bug resolution efficiency
- workload distribution
- process bottlenecks
- sprint health

This project models those scenarios using realistic bug lifecycle data.

---

## Business Questions
- Which projects generate the most defects?
- Are teams keeping up with incoming bugs or accumulating backlog?
- Which developers contribute most to bug resolution?
- How much time is lost due to blocked issues?
- Which sprints show risk signals?

---

## Skills Demonstrated
- Complex JOINs across multiple tables
- Aggregations and grouping
- Window functions (LAG, DENSE_RANK)
- Common Table Expressions (CTEs)
- Time-based lifecycle analysis
- KPI calculation and classification logic

---

## Key Analyses
- Reopen rate by project (quality indicator)
- Developer ranking and performance gap analysis
- Sprint backlog evolution and trend detection
- Time spent in blocked status (process inefficiencies)
- Sprint health classification based on multiple signals

---

## Project Structure
qa-bug-analytics/
├── schema.sql
├── data.sql
├── queries/
│ ├── 01_basic.sql
│ ├── 02_intermediate.sql
│ ├── 03_advanced.sql
│ └── 04_kpis.sql

---

## How to Run
1. Create the database using `schema.sql`
2. Insert data using `data.sql`
3. Run queries from the `queries/` folder in order of complexity

---

## Key Insights
- High reopen rates suggest instability in fixes or insufficient validation.
- Blocked bugs significantly increase total lifecycle time, impacting delivery flow.
- Some sprints accumulate backlog consistently, indicating capacity or prioritization issues.
- Developer contribution varies not only in volume but also in critical bug resolution.

---

## Tech Stack
- MySQL