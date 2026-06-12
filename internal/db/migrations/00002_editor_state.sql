-- +goose Up
-- +goose StatementBegin
CREATE TABLE editor_state (
    lesson_path TEXT PRIMARY KEY,
    content     TEXT NOT NULL,
    updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin
DROP TABLE editor_state;
-- +goose StatementEnd
