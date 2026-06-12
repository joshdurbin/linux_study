package db

import (
	"database/sql"
	"embed"
	"fmt"
	"path/filepath"

	"github.com/pressly/goose/v3"
	_ "modernc.org/sqlite"
)

//go:embed migrations/*.sql
var migrationsFS embed.FS

// Open opens a SQLite database (pure-Go driver) and ensures the directory exists.
// Sets pragmas appropriate for a long-running web server.
func Open(path string) (*sql.DB, error) {
	if dir := filepath.Dir(path); dir != "." && dir != "" {
		// caller is responsible for creating the dir; nothing to do here for now
	}
	dsn := fmt.Sprintf("file:%s?_pragma=journal_mode(WAL)&_pragma=busy_timeout(5000)&_pragma=foreign_keys(1)", path)
	conn, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, err
	}
	if err := conn.Ping(); err != nil {
		conn.Close()
		return nil, err
	}
	conn.SetMaxOpenConns(1) // serialize writes; SQLite has one writer anyway
	return conn, nil
}

// Migrate brings the schema up to date using goose with the embedded migrations.
// Called automatically by the serve command on startup — there is no exposed
// CLI surface for migration; the binary owns its schema.
func Migrate(conn *sql.DB) error {
	goose.SetBaseFS(migrationsFS)
	goose.SetLogger(goose.NopLogger())
	if err := goose.SetDialect("sqlite3"); err != nil {
		return fmt.Errorf("goose dialect: %w", err)
	}
	if err := goose.Up(conn, "migrations"); err != nil {
		return fmt.Errorf("goose up: %w", err)
	}
	return nil
}
