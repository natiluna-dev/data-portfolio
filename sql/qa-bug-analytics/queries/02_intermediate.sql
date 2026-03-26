-- ===============================
-- Level 2 - Intermediate Queries
-- ===============================
-- These queries focus on team execution, bug resolution efficiency,
-- developer contribution, and backlog aging.

-- ===============================================
-- 4) Average resolution time per severity
-- ===============================================
-- This metric helps identify whether higher-severity bugs are being
-- resolved faster than lower-priority issues.
SELECT severity, 
	   ROUND(AVG(DATEDIFF(resolved_date, created_date)), 2) AS avg_days_to_resolve
FROM bugs
WHERE resolved_date IS NOT NULL
GROUP BY severity
ORDER BY CASE severity
    WHEN 'Critical' THEN 1
    WHEN 'High' THEN 2
    WHEN 'Medium' THEN 3
    WHEN 'Low' THEN 4
END;

-- ===============================================
-- 5) Close rate per sprint
-- ===============================================
-- Helps evaluate sprint execution by comparing total bugs vs closed 
-- bugs within each sprint.
SELECT 
	p.project_name, 
    s.sprint_name, 
    COUNT(*) AS total_bugs, 
    SUM(CASE WHEN b.status = 'Closed' THEN 1 ELSE 0 END) AS closed_bugs,
    ROUND( SUM(CASE WHEN b.status = 'Closed' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 3) AS close_rate_per_sprint
FROM bugs b
JOIN sprints s ON b.sprint_id = s.sprint_id
JOIN projects p ON b.project_id = p.project_id
GROUP BY p.project_name, s.sprint_name
ORDER BY p.project_name, s.sprint_name;

-- ===============================================
-- 6) Developer ranking by closed bugs.
-- ===============================================
-- Compares bug closure volume across developers and highlights who resolved 
-- the most high-impact issues.
SELECT 
    d.dev_id,
	d.dev_name,
    SUM(CASE WHEN b.status='Closed' THEN 1 ELSE 0 END) closed_bugs, 
    SUM(CASE WHEN b.status='Closed' AND b.severity IN ('Critical','High') THEN 1 ELSE 0 END) AS closed_crit_high
FROM developers d 
LEFT JOIN bugs b ON b.assignee_id = d.dev_id 
GROUP BY d.dev_id, d.dev_name
ORDER BY closed_bugs DESC, closed_crit_high DESC, d.dev_name; 

-- ===============================================
-- 7) Aging report: open bugs ordered by oldest
-- ===============================================
-- Aging helps identify unresolved issues that may be increasing delivery risk over time.
SELECT 
	b.bug_id AS ID, 
    b.title, 
	b.status,
    d.dev_name AS assignee,
    b.created_date,
    DATEDIFF(CURDATE(),b. created_date) AS days_open
FROM bugs b
LEFT JOIN developers d ON b.assignee_id = d.dev_id
WHERE b.status IN ('Open', 'In Progress', 'Blocked')
ORDER BY days_open DESC, b.severity;