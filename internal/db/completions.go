package db

import (
	"context"
	"database/sql"
)

// CompletionStore provides server-side lesson completion tracking backed by
// the exercise_checks table (migration 00003). It is deliberately separate from
// the sqlc-generated store so adding new queries doesn't require a sqlc regen.
type CompletionStore struct {
	db *sql.DB
}

func NewCompletionStore(db *sql.DB) *CompletionStore { return &CompletionStore{db: db} }

// RecordCheck inserts an exercise check result.
func (s *CompletionStore) RecordCheck(ctx context.Context, sessionID, lessonPath, section string, passed bool) error {
	p := 0
	if passed {
		p = 1
	}
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO exercise_checks (session_id, lesson_path, section, passed) VALUES (?, ?, ?, ?)`,
		sessionID, lessonPath, section, p,
	)
	return err
}

// CompletedPaths returns all distinct lesson_paths that have at least one
// passing check, optionally scoped to a single session (pass "" for global).
func (s *CompletionStore) CompletedPaths(ctx context.Context, sessionID string) ([]string, error) {
	var (
		rows *sql.Rows
		err  error
	)
	if sessionID != "" {
		rows, err = s.db.QueryContext(ctx,
			`SELECT DISTINCT lesson_path FROM exercise_checks WHERE passed = 1 AND session_id = ?`,
			sessionID,
		)
	} else {
		rows, err = s.db.QueryContext(ctx,
			`SELECT DISTINCT lesson_path FROM exercise_checks WHERE passed = 1`,
		)
	}
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var paths []string
	for rows.Next() {
		var p string
		if err := rows.Scan(&p); err != nil {
			return nil, err
		}
		paths = append(paths, p)
	}
	return paths, rows.Err()
}

// WeeklyStats returns how many distinct lessons were completed per ISO week,
// scoped to a session if provided, ordered most-recent first.
func (s *CompletionStore) WeeklyStats(ctx context.Context, sessionID string) ([]WeekStat, error) {
	q := `
		SELECT strftime('%Y-W%W', checked_at) AS week,
		       COUNT(DISTINCT lesson_path)    AS lessons
		FROM exercise_checks
		WHERE passed = 1`
	args := []any{}
	if sessionID != "" {
		q += " AND session_id = ?"
		args = append(args, sessionID)
	}
	q += " GROUP BY week ORDER BY week DESC LIMIT 52"

	rows, err := s.db.QueryContext(ctx, q, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var stats []WeekStat
	for rows.Next() {
		var ws WeekStat
		if err := rows.Scan(&ws.Week, &ws.Lessons); err != nil {
			return nil, err
		}
		stats = append(stats, ws)
	}
	return stats, rows.Err()
}

type WeekStat struct {
	Week    string `json:"week"`
	Lessons int    `json:"lessons"`
}
