-- +goose Up
-- +goose StatementBegin
CREATE TABLE sessions (
    id TEXT PRIMARY KEY,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_seen_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE lesson_opens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_opens_lesson ON lesson_opens(lesson_path);
CREATE INDEX idx_opens_section ON lesson_opens(section);

CREATE TABLE time_spent (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    seconds INTEGER NOT NULL,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_time_lesson ON time_spent(lesson_path);
CREATE INDEX idx_time_section ON time_spent(section);

CREATE TABLE hint_reveals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    hint_index INTEGER NOT NULL,
    revealed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_hints_lesson ON hint_reveals(lesson_path);

CREATE TABLE solution_reveals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    revealed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_reveals_lesson ON solution_reveals(lesson_path);

CREATE TABLE code_runs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    success INTEGER NOT NULL,
    ran_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_runs_lesson ON code_runs(lesson_path);
CREATE INDEX idx_runs_section ON code_runs(section);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE code_runs;
DROP TABLE solution_reveals;
DROP TABLE hint_reveals;
DROP TABLE time_spent;
DROP TABLE lesson_opens;
DROP TABLE sessions;
-- +goose StatementEnd
