# QA Bug Analytics

## Overview

This project analyzes bug tracking data with SQL to understand quality issues, team execution, and sprint risk.

It is designed as a portfolio project for a QA professional moving into data analytics. The analysis turns bug lifecycle data into simple business questions, measurable KPIs, and practical recommendations.

## Business Questions

- Which projects generate the most bugs?
- Are teams closing bugs fast enough during each sprint?
- Which bugs or projects show more reopen activity?
- Where do blocked issues create delivery problems?
- Which sprints need more attention before release?
- What actions can a team take based on the KPI results?

## Dataset

The dataset is synthetic, but it was designed to look like a real QA workflow.

It includes:

- 4 software projects
- 7 developers
- 8 sprints
- 35 bugs
- 147 bug status history events

## Tools

- MySQL
- SQL

## Analytical Approach

The project is organized in three parts:

- `schema.sql` creates the tables
- `data.sql` loads the sample data
- `queries/` contains the analysis from basic queries to KPI-focused queries

The analysis uses a fixed reference date of `2026-03-05` so aging and lifecycle metrics stay reproducible.

## Main KPIs

| KPI | What it shows |
| --- | --- |
| Reopen Rate | How often bugs come back after being resolved or closed |
| Closure Rate | How much work is being completed in a sprint |
| Blocked Rate | How much work is delayed by blockers |
| Cycle Time | How long bugs take to move from creation to resolution |
| Backlog Change | Whether a sprint reduces or increases unresolved work |
| Sprint Health | A simple label that combines the main risk signals |

## Analysis Included

- open bug listing by project and sprint
- bug count by project and severity
- top components with the most bugs
- average resolution time by severity
- closure rate by sprint
- developer ranking by closed bugs
- aging report for open bugs
- sprint comparison with `LAG`
- cycle time calculation
- reopened bug detection
- reopen rate by project
- blocked time per bug
- sprint health classification
- recommended action by sprint

## Example Insights

- High reopen rates can suggest weak validation before closing a bug.
- Blocked bugs can increase total bug lifetime and create delivery risk.
- Some sprints accumulate unresolved work instead of reducing the backlog.
- Sprint health is easier to understand when several signals are combined, not only closure rate.

## Recommended Actions

- Review validation criteria in projects with high reopen activity.
- Escalate dependencies for bugs that spend too much time blocked.
- Prioritize critical bugs before lower-severity work.
- Use sprint health as an early warning signal in sprint reviews.

## Skills Demonstrated

- SQL joins across multiple tables
- grouped metrics and aggregations
- conditional logic with `CASE`
- Common Table Expressions
- window functions such as `LAG`, `LEAD`, and `DENSE_RANK`
- date and lifecycle analysis
- KPI design and business interpretation

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

## Limitations

- This is a synthetic dataset, not production data.
- The project is descriptive and rule-based.
- There is no dashboard in this version.
- Sprint health uses simple thresholds for explanation purposes.
