# QA Bug Analytics - SQL Project

## Overview
This project simulates a QA analytics environment using MySQL. It analyzes bug tracking data across projects, developers, and sprints to identify delivery risks, quality issues, and workflow bottlenecks.

The project is designed from the perspective of a QA professional moving into data analytics: it translates defect lifecycle data into business questions, KPIs, and actionable recommendations for QA Leads, Product Owners, and Engineering Managers.

## Business Context
Software teams need visibility into defect trends before they become release risks. This analysis focuses on:
- bug resolution efficiency
- reopen patterns
- blocked work
- sprint execution
- backlog movement
- high-risk defects

## Business Questions
- Which projects generate the most defects?
- Are teams closing bugs fast enough during each sprint?
- Which bugs or projects show quality instability through reopen activity?
- Where are blocked issues creating delivery bottlenecks?
- Which sprints need management attention before release?
- What actions should teams take based on the KPI signals?

## Dataset
The dataset is synthetic but modeled after real QA workflows. It includes:
- 4 software projects
- 7 developers
- 8 sprints
- 35 bugs
- 147 bug status history events

## Assumptions
- A reopened bug is any bug that moves from `Resolved` or `Closed` back to `Open`.
- Current backlog includes bugs with status `Open`, `In Progress`, or `Blocked`.
- Closure rate is calculated from bugs whose current status is `Closed`.
- Blocked time is calculated from status history intervals.
- The analysis date is fixed at `2026-03-05` so aging and lifecycle metrics are reproducible.
- Sprint health thresholds are intentionally simple and explainable for non-technical stakeholders.

## Main KPIs
| KPI | Purpose |
|---|---|
| Reopen Rate | Measures fix quality and validation effectiveness |
| Closure Rate | Measures sprint execution |
| Blocked Rate | Identifies workflow bottlenecks and external dependencies |
| Cycle Time | Measures time from bug creation to resolution |
| Backlog Change | Shows whether a sprint is reducing or accumulating unresolved work |
| Sprint Health | Combines closure, reopen, blocked, and critical defect signals |

## Key Analyses
- Reopen rate by project
- Developer closure ranking and gap analysis
- Sprint backlog trend using window functions
- Time spent blocked per bug
- Sprint health classification
- Recommended action per sprint

## Executive Summary
The analysis identifies quality and delivery risks across several simulated product areas. Reopened bugs point to possible fix instability or insufficient validation criteria. Blocked P1/P2 issues highlight workflow dependencies that could slow delivery. Sprints with low closure rates, critical bugs, and blocked work are classified as higher-risk and require management attention.

## Sample Insights
- High reopen rates suggest that fixes may need stronger validation before closure.
- Blocked bugs can significantly increase total lifecycle time and create hidden delivery risk.
- Some sprints accumulate unresolved work, which may indicate capacity, prioritization, or dependency issues.
- Developer contribution should be evaluated by both volume and impact, especially critical and high-severity defects.
- Sprint health is more useful when multiple signals are combined instead of relying on closure rate alone.

## Recommended Actions
- Review acceptance criteria and regression coverage for projects with high reopen rates.
- Escalate dependencies for bugs spending a high share of their lifecycle blocked.
- Prioritize critical bugs before adding lower-severity work to sprint scope.
- Use sprint health classification as an early warning signal during sprint reviews.
- Track backlog change over time to detect whether quality pressure is increasing.

## Skills Demonstrated
- SQL joins across normalized tables
- Aggregations and grouped metrics
- Conditional calculations with `CASE`
- Common Table Expressions
- Window functions including `LAG`, `LEAD`, and `DENSE_RANK`
- Date and lifecycle analysis
- KPI design and stakeholder-oriented recommendation logic

## Project Structure
```text
qa-bug-analytics/
├── schema.sql
├── data.sql
├── queries/
│   ├── 01_basic.sql
│   ├── 02_intermediate.sql
│   ├── 03_advanced.sql
│   └── 04_kpis.sql
└── README.md
```

## How to Run
1. Create the database and tables:
   ```sql
   SOURCE schema.sql;
   ```

2. Insert the sample data:
   ```sql
   SOURCE data.sql;
   ```

3. Run the query files in order:
   ```sql
   SOURCE queries/01_basic.sql;
   SOURCE queries/02_intermediate.sql;
   SOURCE queries/03_advanced.sql;
   SOURCE queries/04_kpis.sql;
   ```

## Tech Stack
- MySQL
