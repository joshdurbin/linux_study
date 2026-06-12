-- +goose Up
-- +goose StatementBegin
CREATE TABLE exercise_checks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    passed INTEGER NOT NULL,
    checked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_checks_lesson ON exercise_checks(lesson_path);
CREATE INDEX idx_checks_session ON exercise_checks(session_id);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE exercise_checks;
-- +goose StatementEnd
