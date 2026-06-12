package store

import (
	"context"
)

// ── Session ───────────────────────────────────────────────────────────────────

const ensureSession = `INSERT INTO sessions (id) VALUES (?)
ON CONFLICT(id) DO UPDATE SET last_seen_at = CURRENT_TIMESTAMP`

func (q *Queries) EnsureSession(ctx context.Context, id string) error {
	_, err := q.db.ExecContext(ctx, ensureSession, id)
	return err
}

// ── Lesson opens ──────────────────────────────────────────────────────────────

const recordOpen = `INSERT INTO lesson_opens (session_id, lesson_path, section) VALUES (?, ?, ?)`

type RecordOpenParams struct {
	SessionID  string `json:"session_id"`
	LessonPath string `json:"lesson_path"`
	Section    string `json:"section"`
}

func (q *Queries) RecordOpen(ctx context.Context, arg RecordOpenParams) error {
	_, err := q.db.ExecContext(ctx, recordOpen, arg.SessionID, arg.LessonPath, arg.Section)
	return err
}

// ── Time spent ────────────────────────────────────────────────────────────────

const recordTimeSpent = `INSERT INTO time_spent (session_id, lesson_path, section, seconds) VALUES (?, ?, ?, ?)`

type RecordTimeSpentParams struct {
	SessionID  string `json:"session_id"`
	LessonPath string `json:"lesson_path"`
	Section    string `json:"section"`
	Seconds    int64  `json:"seconds"`
}

func (q *Queries) RecordTimeSpent(ctx context.Context, arg RecordTimeSpentParams) error {
	_, err := q.db.ExecContext(ctx, recordTimeSpent,
		arg.SessionID, arg.LessonPath, arg.Section, arg.Seconds)
	return err
}

// ── Exercise checks (code_runs table) ────────────────────────────────────────

const recordCodeRun = `INSERT INTO code_runs (session_id, lesson_path, section, duration_ms, success)
VALUES (?, ?, ?, ?, ?)`

type RecordCodeRunParams struct {
	SessionID  string `json:"session_id"`
	LessonPath string `json:"lesson_path"`
	Section    string `json:"section"`
	DurationMs int64  `json:"duration_ms"`
	Success    int64  `json:"success"`
}

func (q *Queries) RecordCodeRun(ctx context.Context, arg RecordCodeRunParams) error {
	_, err := q.db.ExecContext(ctx, recordCodeRun,
		arg.SessionID, arg.LessonPath, arg.Section, arg.DurationMs, arg.Success)
	return err
}

// ── Aggregate stats ───────────────────────────────────────────────────────────

const overallStats = `SELECT
    (SELECT COUNT(*) FROM sessions)                        AS sessions,
    (SELECT COUNT(*) FROM lesson_opens)                    AS opens,
    (SELECT COALESCE(SUM(seconds), 0) FROM time_spent)     AS total_seconds,
    (SELECT COUNT(*) FROM code_runs)                       AS code_runs,
    (SELECT COUNT(*) FROM code_runs WHERE success = 1)     AS successful_runs`

type OverallStatsRow struct {
	Sessions       int64       `json:"sessions"`
	Opens          int64       `json:"opens"`
	TotalSeconds   interface{} `json:"total_seconds"`
	CodeRuns       int64       `json:"code_runs"`
	SuccessfulRuns int64       `json:"successful_runs"`
}

func (q *Queries) OverallStats(ctx context.Context) (OverallStatsRow, error) {
	row := q.db.QueryRowContext(ctx, overallStats)
	var i OverallStatsRow
	err := row.Scan(&i.Sessions, &i.Opens, &i.TotalSeconds, &i.CodeRuns, &i.SuccessfulRuns)
	return i, err
}

const sectionTotals = `SELECT
    section,
    (SELECT COUNT(*) FROM lesson_opens o WHERE o.section = s.section)               AS opens,
    (SELECT COALESCE(SUM(seconds), 0) FROM time_spent t WHERE t.section = s.section) AS total_seconds,
    (SELECT COUNT(*) FROM code_runs c WHERE c.section = s.section)                   AS code_runs
FROM (
    SELECT DISTINCT section FROM lesson_opens
    UNION SELECT DISTINCT section FROM time_spent
    UNION SELECT DISTINCT section FROM code_runs
) s
ORDER BY total_seconds DESC`

type SectionTotalsRow struct {
	Section      string      `json:"section"`
	Opens        int64       `json:"opens"`
	TotalSeconds interface{} `json:"total_seconds"`
	CodeRuns     int64       `json:"code_runs"`
}

func (q *Queries) SectionTotals(ctx context.Context) ([]SectionTotalsRow, error) {
	rows, err := q.db.QueryContext(ctx, sectionTotals)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []SectionTotalsRow
	for rows.Next() {
		var i SectionTotalsRow
		if err := rows.Scan(&i.Section, &i.Opens, &i.TotalSeconds, &i.CodeRuns); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	return items, rows.Err()
}

const lessonTotals = `SELECT
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
ORDER BY total_seconds DESC`

type LessonTotalsRow struct {
	LessonPath   string      `json:"lesson_path"`
	Section      string      `json:"section"`
	Opens        int64       `json:"opens"`
	TotalSeconds interface{} `json:"total_seconds"`
	CodeRuns     int64       `json:"code_runs"`
}

func (q *Queries) LessonTotals(ctx context.Context) ([]LessonTotalsRow, error) {
	rows, err := q.db.QueryContext(ctx, lessonTotals)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []LessonTotalsRow
	for rows.Next() {
		var i LessonTotalsRow
		if err := rows.Scan(&i.LessonPath, &i.Section, &i.Opens, &i.TotalSeconds, &i.CodeRuns); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	return items, rows.Err()
}
