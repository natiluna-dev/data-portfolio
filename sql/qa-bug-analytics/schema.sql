-- =========================
-- QA Bug Analytics - Schema
-- =========================

CREATE DATABASE qa_analytics;
USE qa_analytics;

DROP TABLE IF EXISTS bug_status_history;
DROP TABLE IF EXISTS bugs;
DROP TABLE IF EXISTS sprints;
DROP TABLE IF EXISTS developers;
DROP TABLE IF EXISTS projects;

CREATE TABLE projects (
  project_id   INTEGER PRIMARY KEY,
  project_name TEXT NOT NULL,
  domain       TEXT
);

CREATE TABLE developers (
  dev_id   INTEGER PRIMARY KEY,
  dev_name TEXT NOT NULL,
  team     TEXT
);

CREATE TABLE sprints (
  sprint_id    INTEGER PRIMARY KEY,
  project_id   INTEGER NOT NULL,
  sprint_name  TEXT NOT NULL,
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(project_id)
);

CREATE TABLE bugs (
  bug_id        INTEGER PRIMARY KEY,
  project_id    INTEGER NOT NULL,
  sprint_id     INTEGER NOT NULL,
  created_date  DATE NOT NULL,
  resolved_date DATE,
  severity      TEXT NOT NULL CHECK (severity IN ('Critical','High','Medium','Low')),
  priority      TEXT NOT NULL CHECK (priority IN ('P1','P2','P3','P4')),
  status        TEXT NOT NULL CHECK (status IN ('Open','In Progress','Blocked','Resolved','Closed')),
  assignee_id   INTEGER,
  reporter      TEXT,
  component     TEXT,
  title         TEXT,
  FOREIGN KEY (project_id) REFERENCES projects(project_id),
  FOREIGN KEY (sprint_id) REFERENCES sprints(sprint_id),
  FOREIGN KEY (assignee_id) REFERENCES developers(dev_id)
);

CREATE TABLE bug_status_history (
  hist_id     INTEGER PRIMARY KEY,
  bug_id      INTEGER NOT NULL,
  changed_at  DATETIME NOT NULL,
  old_status  TEXT NOT NULL,
  new_status  TEXT NOT NULL,
  changed_by  TEXT,
  FOREIGN KEY (bug_id) REFERENCES bugs(bug_id)
);
