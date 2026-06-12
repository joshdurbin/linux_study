package store

import "time"

type CodeRun struct {
	ID         int64     `json:"id"`
	SessionID  string    `json:"session_id"`
	LessonPath string    `json:"lesson_path"`
	Section    string    `json:"section"`
	DurationMs int64     `json:"duration_ms"`
	Success    int64     `json:"success"`
	RanAt      time.Time `json:"ran_at"`
}

type LessonOpen struct {
	ID         int64     `json:"id"`
	SessionID  string    `json:"session_id"`
	LessonPath string    `json:"lesson_path"`
	Section    string    `json:"section"`
	OpenedAt   time.Time `json:"opened_at"`
}

type Session struct {
	ID         string    `json:"id"`
	CreatedAt  time.Time `json:"created_at"`
	LastSeenAt time.Time `json:"last_seen_at"`
}

type TimeSpent struct {
	ID         int64     `json:"id"`
	SessionID  string    `json:"session_id"`
	LessonPath string    `json:"lesson_path"`
	Section    string    `json:"section"`
	Seconds    int64     `json:"seconds"`
	RecordedAt time.Time `json:"recorded_at"`
}
