package main

import (
	"context"
	"embed"
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"os/signal"
	"path/filepath"
	"strings"
	"syscall"
	"time"

	"github.com/coder/websocket"
	"github.com/coder/websocket/wsjson"
	"github.com/joshdurbin/linux_study/internal/analytics"
	"github.com/joshdurbin/linux_study/internal/db"
	"github.com/joshdurbin/linux_study/internal/docker"
	"github.com/spf13/viper"
)

//go:embed web/*.html
var webFS embed.FS

//go:embed Dockerfile.linux
var dockerfileLinux []byte

type server struct {
	repoRoot    string
	tracker     *analytics.Tracker
	dockerMgr   *docker.Manager
	completions *db.CompletionStore
}

func runServe() error {
	repoRoot, err := filepath.Abs(viper.GetString("root"))
	if err != nil {
		return err
	}

	conn, err := openDB()
	if err != nil {
		return err
	}
	defer conn.Close()
	if err := db.Migrate(conn); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	s := &server{
		repoRoot:    repoRoot,
		tracker:     analytics.New(conn, viper.GetBool("analytics_enabled")),
		completions: db.NewCompletionStore(conn),
	}

	// Docker manager for the Linux terminal (non-fatal if Docker unavailable).
	if mgr, err := docker.NewManager(context.Background()); err != nil {
		log.Printf("docker unavailable — terminal disabled: %v", err)
	} else {
		s.dockerMgr = mgr
		if !mgr.Status().ImageReady {
			mgr.BuildStudyImage(context.Background(), dockerfileLinux)
		}
	}

	mux := http.NewServeMux()

	// Root redirects to /linux.
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		http.Redirect(w, r, "/linux", http.StatusFound)
	})

	mux.HandleFunc("/linux", s.handleLinux)
	mux.HandleFunc("/dashboard", s.handleDashboard)

	mux.HandleFunc("/api/linux/file", s.handleLinuxFile)
	mux.HandleFunc("/api/linux/check", s.handleLinuxCheck)
	mux.HandleFunc("/api/linux/completions", s.handleLinuxCompletions)
	mux.HandleFunc("/api/linux/progress", s.handleLinuxProgress)
	mux.HandleFunc("/api/linux/status", s.handleLinuxStatus)
	mux.HandleFunc("/api/linux/stats", s.handleLinuxStats)

	mux.HandleFunc("/ws", s.handleWS)
	mux.HandleFunc("/ws/linux-terminal", s.handleLinuxTerminalWS)

	handler := s.tracker.SessionMiddleware(mux)

	addr := viper.GetString("addr")
	srv := &http.Server{Addr: addr, Handler: handler}

	go func() {
		log.Printf("linux_study serving from %s on http://localhost%s (analytics=%v)",
			repoRoot, addr, s.tracker.Enabled())
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)
	<-stop
	log.Println("shutting down")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if s.dockerMgr != nil {
		s.dockerMgr.Shutdown(ctx)
	}
	return srv.Shutdown(ctx)
}

func (s *server) handleDashboard(w http.ResponseWriter, r *http.Request) {
	tmpl, err := template.ParseFS(webFS, "web/dashboard.html")
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	if err := tmpl.Execute(w, nil); err != nil {
		log.Println(err)
	}
}

// handleWS manages the time-tracking WebSocket used by the study page.
// Protocol: {"type":"focus","path":"linux/..."} | {"type":"blur"} | {"type":"tick","seconds":N}
func (s *server) handleWS(w http.ResponseWriter, r *http.Request) {
	c, err := websocket.Accept(w, r, &websocket.AcceptOptions{InsecureSkipVerify: true})
	if err != nil {
		log.Println("ws accept:", err)
		return
	}
	defer c.Close(websocket.StatusInternalError, "closing")

	sid := analytics.SessionID(r)
	currentPath := ""
	ctx := r.Context()

	for {
		var msg struct {
			Type    string `json:"type"`
			Path    string `json:"path"`
			Seconds int64  `json:"seconds"`
		}
		if err := wsjson.Read(ctx, c, &msg); err != nil {
			break
		}
		switch msg.Type {
		case "focus":
			if strings.HasPrefix(msg.Path, "linux/") {
				currentPath = msg.Path
			}
		case "blur":
			currentPath = ""
		case "tick":
			if currentPath == "" || msg.Seconds <= 0 {
				continue
			}
			_ = s.tracker.RecordTime(ctx, sid, currentPath, msg.Seconds)
		}
	}
	c.Close(websocket.StatusNormalClosure, "")
}

// prettify converts a block/file name to a human-readable sidebar label.
func prettify(name string) string {
	s := strings.TrimPrefix(name, "block")
	for len(s) > 0 && s[0] >= '0' && s[0] <= '9' {
		s = s[1:]
	}
	s = strings.TrimPrefix(s, "_")
	s = strings.ReplaceAll(s, "_", " ")
	if s == "" {
		return name
	}
	parts := strings.Fields(s)
	for i, p := range parts {
		if len(p) > 0 {
			parts[i] = strings.ToUpper(p[:1]) + p[1:]
		}
	}
	return strings.Join(parts, " ")
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
