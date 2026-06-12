-- name: EnsureSession :exec
INSERT INTO sessions (id) VALUES (?)
ON CONFLICT(id) DO UPDATE SET last_seen_at = CURRENT_TIMESTAMP;

-- name: RecordOpen :exec
INSERT INTO lesson_opens (session_id, lesson_path, section) VALUES (?, ?, ?);

-- name: RecordTimeSpent :exec
INSERT INTO time_spent (session_id, lesson_path, section, seconds) VALUES (?, ?, ?, ?);

-- name: RecordCodeRun :exec
INSERT INTO code_runs (session_id, lesson_path, section, duration_ms, success)
VALUES (?, ?, ?, ?, ?);

-- name: OverallStats :one
SELECT
    (SELECT COUNT(*) FROM sessions)                        AS sessions,
    (SELECT COUNT(*) FROM lesson_opens)                    AS opens,
    (SELECT COALESCE(SUM(seconds), 0) FROM time_spent)     AS total_seconds,
    (SELECT COUNT(*) FROM code_runs)                       AS code_runs,
    (SELECT COUNT(*) FROM code_runs WHERE success = 1)     AS successful_runs;

-- name: SectionTotals :many
SELECT
    section,
    (SELECT COUNT(*) FROM lesson_opens o WHERE o.section = s.section)               AS opens,
    (SELECT COALESCE(SUM(seconds), 0) FROM time_spent t WHERE t.section = s.section) AS total_seconds,
    (SELECT COUNT(*) FROM code_runs c WHERE c.section = s.section)                   AS code_runs
FROM (
    SELECT DISTINCT section FROM lesson_opens
    UNION SELECT DISTINCT section FROM time_spent
    UNION SELECT DISTINCT section FROM code_runs
) s
ORDER BY total_seconds DESC;

-- name: LessonTotals :many
SELECT
    lesson_path,
    section,
    (SELECT COUNT(*) FROM lesson_opens o WHERE o.lesson_path = l.lesson_path)               AS opens,
    (SELECT COALESCE(SUM(seconds), 0) FROM time_spent t WHERE t.lesson_path = l.lesson_path) AS total_seconds,
    (SELECT COUNT(*) FROM code_runs c WHERE c.lesson_path = l.lesson_path)                   AS code_runs
FROM (
    SELECT DISTINCT lesson_path, section FROM lesson_opens
    UNION SELECT DISTINCT lesson_path, section FROM time_spent
    UNION SELECT DISTINCT lesson_path, section FROM code_runs
) l
ORDER BY total_seconds DESC;
