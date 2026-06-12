package analytics

import (
	"context"
	"database/sql"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/joshdurbin/linux_study/internal/db/store"
)

const SessionCookie = "study_session"

type Tracker struct {
	q       *store.Queries
	enabled bool
}

func New(conn *sql.DB, enabled bool) *Tracker {
	return &Tracker{q: store.New(conn), enabled: enabled}
}

func (t *Tracker) Enabled() bool { return t != nil && t.enabled }

// SectionFromPath returns the top-level section from a lesson path (e.g. "linux/block1_basics").
func SectionFromPath(p string) string {
	parts := strings.SplitN(p, "/", 3)
	if len(parts) >= 2 {
		return parts[0] + "/" + parts[1]
	}
	if len(parts) > 0 {
		return parts[0]
	}
	return "unknown"
}

// SessionMiddleware ensures every request carries a study_session cookie and
// records the session in the database.
func (t *Tracker) SessionMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var sid string
		if c, err := r.Cookie(SessionCookie); err == nil && c.Value != "" {
			sid = c.Value
		} else {
			sid = uuid.NewString()
			http.SetCookie(w, &http.Cookie{
				Name:     SessionCookie,
				Value:    sid,
				Path:     "/",
				HttpOnly: true,
				SameSite: http.SameSiteLaxMode,
				Expires:  time.Now().Add(365 * 24 * time.Hour),
			})
		}
		if t.Enabled() {
			_ = t.q.EnsureSession(r.Context(), sid)
		}
		ctx := context.WithValue(r.Context(), sessionKey{}, sid)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

type sessionKey struct{}

// SessionID extracts the session ID injected by SessionMiddleware.
func SessionID(r *http.Request) string {
	if v := r.Context().Value(sessionKey{}); v != nil {
		return v.(string)
	}
	return ""
}

func (t *Tracker) RecordOpen(ctx context.Context, sid, lessonPath string) error {
	if !t.Enabled() {
		return nil
	}
	return t.q.RecordOpen(ctx, store.RecordOpenParams{
		SessionID:  sid,
		LessonPath: lessonPath,
		Section:    SectionFromPath(lessonPath),
	})
}

func (t *Tracker) RecordTime(ctx context.Context, sid, lessonPath string, seconds int64) error {
	if !t.Enabled() || seconds <= 0 {
		return nil
	}
	return t.q.RecordTimeSpent(ctx, store.RecordTimeSpentParams{
		SessionID:  sid,
		LessonPath: lessonPath,
		Section:    SectionFromPath(lessonPath),
		Seconds:    seconds,
	})
}

func (t *Tracker) RecordRun(ctx context.Context, sid, lessonPath string, durationMs int64, success bool) error {
	if !t.Enabled() {
		return nil
	}
	s := int64(0)
	if success {
		s = 1
	}
	return t.q.RecordCodeRun(ctx, store.RecordCodeRunParams{
		SessionID:  sid,
		LessonPath: lessonPath,
		Section:    SectionFromPath(lessonPath),
		DurationMs: durationMs,
		Success:    s,
	})
}

func (t *Tracker) Queries() *store.Queries { return t.q }
