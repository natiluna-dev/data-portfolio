-- =================================
-- QA Bug Analytics - KPI Queries
-- =================================
-- This file contains business-oriented SQL analyses designed to evaluate
-- bug quality trends, team performance, delivery flow, and sprint health
-- in a simulated QA environment.

-- ==================================
-- 12) Reopen rate by project
-- ==================================
-- Reopen rate is a quality signal that helps identify instability,
-- incomplete fixes, or unclear validation criteria.
-- A bug is considered reopened when it moves from Resolved or Closed
-- back to Open.
WITH reopened_bugs AS (
SELECT 
	bug_id, 
    SUM(CASE WHEN (old_status in ('Resolved', 'Closed') AND new_status = 'Open') THEN 1 
		ELSE 0 
        END) AS reopen_count
FROM bug_status_history
GROUP BY bug_id
) 
SELECT 
	p.project_name, 
    COUNT(*) AS total_bugs,
    SUM(CASE WHEN r.reopen_count > 0 THEN 1 ELSE 0 END) AS reopened_bugs,
    ROUND(
		SUM(CASE WHEN r.reopen_count > 0 THEN 1 ELSE 0 END) / COUNT(*) * 100.0
		, 2) AS reopen_rate_pct
FROM bugs b
JOIN projects p ON  b.project_id = p.project_id
JOIN reopened_bugs r ON b.bug_id = r.bug_id
GROUP BY p.project_name
ORDER BY reopen_rate_pct DESC, reopened_bugs DESC; 

-- ==================================
-- 13) Developer close ranking with previous developer comparison
-- ==================================
-- Compares developers by number of closed bugs and measures the gap
-- versus the previous ranked developer.
-- This helps show not only ranking position, but also the performance
-- distance between contributors.
WITH closed_by_dev AS (
SELECT 
    b.assignee_id, 
    d.dev_name, 
    COUNT(*) AS closed_bugs
FROM bugs b
JOIN developers d
	ON d.dev_id = b.assignee_id
WHERE b.status = 'Closed'
GROUP BY b.assignee_id, d.dev_name
),
rank_closed_bugs AS (
SELECT 
	DENSE_RANK() OVER(ORDER BY closed_bugs DESC) AS rnk, 
	dev_name, 
    closed_bugs,
    LAG(dev_name) OVER (ORDER BY closed_bugs DESC, dev_name) AS prev_dev_name,
    LAG(closed_bugs) OVER (ORDER BY closed_bugs DESC, dev_name) AS prev_dev_closed_bugs
FROM closed_by_dev
) 
SELECT 	
	rnk, 
    dev_name, 
    closed_bugs,
    prev_dev_name,
    prev_dev_closed_bugs,
    prev_dev_closed_bugs - closed_bugs AS gap_vs_previous_dev,
    ROUND((prev_dev_closed_bugs - closed_bugs) / NULLIF(prev_dev_closed_bugs, 0) * 100.0, 2) AS pct_gap_vs_previous_dev
FROM rank_closed_bugs
ORDER BY rnk, dev_name;

-- ==================================
-- 14) Sprint trend: opened vs closed vs net backlog change
-- ==================================
-- Backlog change shows whether each sprint is reducing incoming bug
-- volume or accumulating unresolved work.
-- The running backlog trend helps reveal whether quality pressure is
-- growing over time within each project.
WITH sprint_closed_bugs AS (
	SELECT 
		sprint_id, 
        COUNT(*) AS closed_bugs_per_sprint
	FROM bugs
	WHERE status = 'Closed'
	GROUP BY sprint_id
), 
sprint_opened_bugs AS (
	SELECT 
		sprint_id, 
        COUNT(*) AS opened_bugs_per_sprint
	FROM bugs
	GROUP BY sprint_id
), 
combined AS (
SELECT 
	s.sprint_id, 
    s.sprint_name, 
    s.project_id,
    s.start_date,
	COALESCE(closed_bugs_per_sprint, 0) AS closed_bugs, 
    COALESCE(opened_bugs_per_sprint, 0) AS opened_bugs
FROM sprints s  
LEFT JOIN sprint_opened_bugs o ON s.sprint_id = o.sprint_id  
LEFT JOIN sprint_closed_bugs c ON s.sprint_id = c.sprint_id
) 
SELECT 
	p.project_name,
	c.sprint_name, 
	c.opened_bugs, 
    c.closed_bugs, 
    c.opened_bugs - c.closed_bugs AS backlog_change,
    LAG(c.sprint_name) 
		OVER(PARTITION BY p.project_id ORDER BY c.start_date) AS prev_sprint, 
	SUM(c.opened_bugs - c.closed_bugs) 
		OVER(PARTITION BY p.project_id ORDER BY c.start_date) AS running_backlog_change
FROM combined c
JOIN projects p ON c.project_id = p.project_id
ORDER BY p.project_name, c.start_date;


-- ==================================
-- 15) Time spent blocked per bug
-- ==================================
-- This analysis measures how long bugs remain in a Blocked state in
-- order to identify workflow interruptions, dependencies, and delivery
-- bottlenecks.
-- It reconstructs status intervals using LEAD(), aggregates blocked
-- time per bug, and compares it against the bug's total lifecycle to
-- estimate blockage severity.
WITH periods AS (
	SELECT 
		bug_id, 
		changed_at AS started_at, 
		COALESCE(LEAD(changed_at) OVER (PARTITION BY bug_id ORDER BY changed_at), NOW()) AS next_change_at, 
        new_status
	FROM bug_status_history
), 
last_bug_activity AS (
	SELECT 
		bug_id, 
		MAX(changed_at) AS last_changed_at
    FROM bug_status_history
    GROUP BY bug_id
),
bug_lifetime AS (
	SELECT b.bug_id, TIMESTAMPDIFF(HOUR, created_date, COALESCE(last_changed_at,NOW()) ) AS total_lifetime_hours
	FROM bugs b
    LEFT JOIN last_bug_activity bla ON b.bug_id = bla.bug_id 
),
time_blocked AS (
	SELECT 
		bug_id, 
		started_at, 
		next_change_at, 
		new_status,
		TIMESTAMPDIFF(HOUR, started_at, next_change_at) AS blocked_hours
	FROM periods
	WHERE new_status = 'Blocked'
),
agg_time AS (
	SELECT  
		bug_id, 
		COUNT(*) AS times_blocked, 
        SUM(blocked_hours) AS total_blocked_hours
	FROM time_blocked
	GROUP BY bug_id
)
SELECT 
	b.bug_id, 
	b.title, 
	p.project_name, 
	b.priority, 
	d.dev_name, 
	b.status,
	COALESCE(agt.times_blocked,0) AS times_blocked, 
	COALESCE(agt.total_blocked_hours,0) AS total_blocked_hours,
	bl.total_lifetime_hours, 
    ROUND(100.0 * COALESCE(agt.total_blocked_hours,0) / NULLIF(bl.total_lifetime_hours, 0), 2) AS pct_lifetime_blocked,
    CASE 
		WHEN COALESCE(agt.total_blocked_hours,0) = 0 THEN 'No Blockers'
		WHEN COALESCE(agt.total_blocked_hours,0) < 5 THEN 'Low'
		WHEN COALESCE(agt.total_blocked_hours,0) < 15 THEN 'Medium'
    ELSE 'High' END AS blockage_level,
    DENSE_RANK() OVER (ORDER BY COALESCE(agt.total_blocked_hours, 0) DESC) AS rank_blocked_hours
FROM bugs b
LEFT JOIN agg_time agt ON b.bug_id = agt.bug_id
LEFT JOIN bug_lifetime bl ON b.bug_id = bl.bug_id
LEFT JOIN developers d ON d.dev_id = b.assignee_id
JOIN projects p ON p.project_id = b.project_id
ORDER BY COALESCE(agt.total_blocked_hours, 0) DESC, b.bug_id;

-- ==================================
-- 16) Sprint health classification
-- ==================================
-- Combines closure rate, blocked bugs, reopened bugs, and critical bug
-- volume into a simple sprint health label.
-- The health score uses rule-based thresholds to classify each sprint
-- as Healthy, Needs Attention, or At Risk.
-- Thresholds were adjusted to reduce sensitivity in small sprint samples.
WITH closed_dates AS (
    SELECT 
        bug_id, 
        MAX(changed_at) AS bug_closed_date
    FROM bug_status_history
    WHERE new_status = 'Closed'
    GROUP BY bug_id
),
resolution_days AS (
	SELECT  
		b.bug_id, 
        b.created_date, 
        cd.bug_closed_date, 
        b.project_id, 
        b.sprint_id, 
        datediff(cd.bug_closed_date, b.created_date) AS bug_resolution_days
	FROM bugs b
	JOIN closed_dates cd ON b.bug_id = cd.bug_id
),
aggregation_data_per_sprint AS (
	SELECT 
		b.project_id, 
        b.sprint_id, 
        COUNT(*) AS total_bugs, 
		SUM(CASE WHEN b.status = 'Closed' THEN 1 ELSE 0 END) AS closed_bugs,
		SUM(CASE WHEN b.status IN ('Open', 'In Progress') THEN 1 ELSE 0 END) AS open_bugs,
        SUM(CASE WHEN b.status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_bugs,
		SUM(CASE WHEN b.status = 'Blocked' THEN 1 ELSE 0 END) AS blocked_bugs, 
		SUM(CASE WHEN b.severity = 'Critical' THEN 1 ELSE 0 END) AS critical_bugs,
		ROUND(AVG(r.bug_resolution_days), 2) AS avg_resolution_days
	FROM bugs b
	LEFT JOIN resolution_days r ON b.bug_id = r.bug_id
	GROUP BY b.project_id, b.sprint_id
),
bugs_reopened_per_sprint AS (
	SELECT  
		b.project_id, 
        b.sprint_id, 
		COUNT(DISTINCT CASE 
			WHEN h.old_status IN ('Resolved', 'Closed') 
            AND h.new_status = 'Open' 
            THEN b.bug_id 
		END) AS reopened_bugs
    FROM bugs b
	JOIN bug_status_history h ON b.bug_id = h.bug_id 
    GROUP BY b.project_id, b.sprint_id
),
final_metrics AS (
	SELECT 
		p.project_name, 
		s.sprint_name, 
		a.total_bugs, 
		a.closed_bugs, 
		a.open_bugs, 
		a.resolved_bugs,
		a.blocked_bugs, 
		a.critical_bugs, 
		a.avg_resolution_days, 
		COALESCE(br.reopened_bugs, 0) AS reopened_bugs, 
		ROUND(a.closed_bugs * 100.0 / NULLIF(a.total_bugs, 0), 2) AS closure_rate,
		ROUND(COALESCE(br.reopened_bugs, 0) * 100.0 / NULLIF(a.total_bugs, 0), 2) AS reopen_rate,
		ROUND(a.blocked_bugs * 100.0 / NULLIF(a.total_bugs, 0), 2) AS blocked_rate
	FROM aggregation_data_per_sprint a
	LEFT JOIN bugs_reopened_per_sprint br ON br.project_id = a.project_id 
		AND br.sprint_id = a.sprint_id
	JOIN projects p ON p.project_id = a.project_id
	JOIN sprints s ON s.sprint_id = a.sprint_id
	ORDER BY a.project_id, a.sprint_id
)
SELECT 
	*,
	CASE
		WHEN (blocked_bugs >= 2 AND blocked_rate >= 20)
		OR (reopened_bugs >= 2 AND reopen_rate >= 20)
		OR critical_bugs >= 2
		OR closure_rate < 40
		THEN 'At Risk'

		WHEN blocked_bugs >= 1
		OR reopened_bugs >= 1
		OR critical_bugs >= 1
		OR closure_rate < 70
		THEN 'Needs Attention'

		ELSE 'Healthy'
	END AS sprint_health
FROM final_metrics
ORDER BY project_name, sprint_name;
