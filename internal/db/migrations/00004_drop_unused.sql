-- +goose Up
-- +goose StatementBegin
-- Remove tables that were only used by the Go study app.
-- hint_reveals and solution_reveals tracked Go study hint/solution reveals.
-- editor_state persisted CodeMirror editor content (no longer needed).
DROP TABLE IF EXISTS hint_reveals;
DROP TABLE IF EXISTS solution_reveals;
DROP TABLE IF EXISTS editor_state;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
CREATE TABLE hint_reveals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    hint_index INTEGER NOT NULL,
    revealed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE solution_reveals (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id TEXT NOT NULL,
    lesson_path TEXT NOT NULL,
    section TEXT NOT NULL,
    revealed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE editor_state (
    lesson_path TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- +goose StatementEnd
