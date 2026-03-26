-- ==================================
-- Level 3 - Advanced (CTE + Windows)
-- ==================================
-- These queries focus on temporal analysis and bug lifecycle behavior
-- using CTEs, date logic, and window functions.

-- ===============================================
-- 8) Compare bug count vs previous sprint (LAG).
-- ===============================================
-- Uses LAG to compare each sprint's bug volume against the previous
-- sprint within the same project.
WITH bugs_per_sprint AS (
SELECT 
	b.project_id, 
    s.sprint_id,
	s.start_date,
	COUNT(*) AS total_bugs
FROM bugs b
JOIN sprints s ON s.sprint_id = b.sprint_id
GROUP BY b.project_id, b.sprint_id, s.start_date
), 
sprint_comparison AS (
SELECT  
	project_id, 
	sprint_id, 
    total_bugs, 
    start_date,
    LAG(sprint_id) OVER (PARTITION BY project_id ORDER BY start_date) AS prev_sprint,
	LAG(total_bugs) OVER (PARTITION BY project_id ORDER BY start_date) AS prev_sprint_total_bugs
from bugs_per_sprint
) 
SELECT 
	p.project_name, 
    s.sprint_id, 
    s.total_bugs, 
    s.prev_sprint,
    (s.total_bugs - s.prev_sprint_total_bugs) AS diff_vs_prev
FROM sprint_comparison s
JOIN projects p ON p.project_id = s.project_id
ORDER BY p.project_name, s.start_date;

-- ===============================================
-- 9) First and last status change per bug.
-- ===============================================
-- Para cada bug: primer cambio de estado y último cambio (min/max changed_at).
-- Shows the lifecycle boundaries of each bug based on the earliest and
-- latest recorded status change.
SELECT
    b.bug_id,
    b.title,
    MIN(h.changed_at) AS first_change,
    MAX(h.changed_at) AS last_change
FROM bugs b
LEFT JOIN bug_status_history h ON b.bug_id = h.bug_id
GROUP BY b.bug_id, b.title
ORDER BY b.bug_id;

-- ===============================================
-- 10) Calculate cycle time (Open → Resolved).
-- ===============================================
-- Measures how many days it took each bug to move from creation to its
-- latest resolved state.
WITH last_resolved AS (
SELECT 
	bug_id, 
	MAX(changed_at) AS last_resolved_date
FROM bug_status_history
WHERE new_status = 'Resolved'
GROUP BY bug_id
)
SELECT 
	b.bug_id,
	b.created_date,
    lr.last_resolved_date, 
    DATEDIFF(lr.last_resolved_date, b.created_date) AS cycle_time
FROM bugs b
JOIN last_resolved lr
	ON b.bug_id = lr.bug_id;

-- ===============================================
-- 11) Detect reopened bugs.
-- ===============================================
-- Identifies bugs that returned to Open after being previously Resolved
-- or Closed.
SELECT 
	b.bug_id, 
    b.title, 
    bsh.changed_at AS reopened_date
FROM bug_status_history bsh
JOIN bugs b ON bsh.bug_id = b.bug_id
WHERE bsh.old_status IN ('Resolved', 'Closed')
AND bsh.new_status = 'Open'
ORDER BY b.bug_id, bsh.changed_at