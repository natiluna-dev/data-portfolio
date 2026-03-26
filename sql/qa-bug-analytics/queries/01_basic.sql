-- =========================
-- Level 1 - Basic Queries
-- =========================

-- ===============================================
-- 1) List all open bugs with project and sprint.
-- ===============================================
SELECT b.bug_id, 
	p.project_name, 
    s.sprint_name, 
    b.severity, 
    b.priority, 
    b.status, 
    b.created_date
FROM bugs b
JOIN projects p ON b.project_id = p.project_id
JOIN sprints s ON b.sprint_id = s.sprint_id
WHERE b.status in ('Open','In Progress','Blocked')
ORDER BY b.created_date, b.bug_id;

-- ===============================================
-- 2) Count bugs per project and severity 
-- ===============================================
SELECT p.project_name, 
	b.severity, 
	COUNT(*) AS bug_count
FROM bugs b
JOIN projects p ON b.project_id = p.project_id
GROUP BY p.project_name, b.severity
ORDER BY p.project_name, bug_count DESC;

-- ===============================================
-- 3) Top 3 components with most bugs.
-- ===============================================
SELECT component, 
	COUNT(*) AS bug_count
FROM bugs 
GROUP BY component
ORDER BY bug_count DESC, component
LIMIT 3;

;