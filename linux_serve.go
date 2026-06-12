package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/coder/websocket"
	"github.com/joshdurbin/linux_study/internal/analytics"
	"github.com/joshdurbin/linux_study/internal/db"
	"github.com/joshdurbin/linux_study/internal/db/store"
)

// linuxSectionDirs are the allowed top-level directories under linux/.
// safePathLinux validates against these, independent of dynamic section loading.
var linuxSectionDirs = []string{
	"linux/block1_basics",
	"linux/block2_intermediate",
	"linux/block3_advanced",
	"linux/block4_tooling",
	"linux/block5_internals",
	"linux/block6_networking",
	"linux/block7_performance",
	"linux/block8_ebpf",
	"linux/block9_containers",
	"linux/block12_references",
}

// LinuxItem is a single Linux lesson (identified by its .md file, not .go).
type LinuxItem struct {
	Name        string
	RelPath     string // path to the .md file, e.g. linux/block1_basics/01_filesystem_navigation.md
	HasExercise bool
	HasCheck    bool
}

// LinuxSection mirrors the Go Section but holds LinuxItems.
type LinuxSection struct {
	Name        string
	Dir         string
	Description string
	Items       []LinuxItem
}

func (s *server) loadLinuxSections() []LinuxSection {
	specs := []struct{ dir, name, desc string }{
		{"linux/block1_basics", "Week 1 — Basics", "Core navigation, files, permissions, processes, and I/O redirection."},
		{"linux/block2_intermediate", "Week 1 — Intermediate", "Shell scripting, text processing, networking, and system services."},
		{"linux/block3_advanced", "Week 1 — Advanced CLI", "Performance debugging, storage, security hardening, and advanced scripting."},
		{"linux/block4_tooling", "Week 1 — Tooling", "vim, tmux, git advanced workflows, and jq/yq."},
		{"linux/block5_internals", "Week 2 — Linux Internals", "/proc, /sys, syscalls, signals, IPC, namespaces intro, and cgroups v2."},
		{"linux/block6_networking", "Week 3 — Networking", "ip/ss, routing, network namespaces, bridges, tcpdump, firewalling, and DNS."},
		{"linux/block7_performance", "Week 4 — Performance", "perf, flame graphs, strace, ftrace, I/O analysis, and the USE method."},
		{"linux/block8_ebpf", "Week 5 — eBPF & Tracing", "eBPF fundamentals, BCC tool survey, and bpftrace one-liners through advanced use."},
		{"linux/block9_containers", "Week 6 — Container Internals", "Namespaces, cgroups, overlayfs, OCI/runc, and containers from scratch."},
		{"linux/block12_references", "Supplemental References", "Curated reference repos, further reading, and hands-on labs organized by topic."},
	}
	var built []LinuxSection
	for _, spec := range specs {
		dirPath := filepath.Join(s.repoRoot, spec.dir)
		info, err := os.Stat(dirPath)
		if err != nil || !info.IsDir() {
			continue
		}
		entries, err := os.ReadDir(dirPath)
		if err != nil {
			log.Printf("linux sections: readdir %s: %v", dirPath, err)
			continue
		}
		sec := LinuxSection{Name: spec.name, Dir: spec.dir, Description: spec.desc}
		for _, e := range entries {
			if e.IsDir() || !strings.HasSuffix(e.Name(), ".md") {
				continue
			}
			if strings.HasSuffix(e.Name(), ".exercise.md") {
				continue
			}
			rel := filepath.ToSlash(filepath.Join(spec.dir, e.Name()))
			base := filepath.Join(dirPath, strings.TrimSuffix(e.Name(), ".md"))
			item := LinuxItem{
				Name:        prettify(strings.TrimSuffix(e.Name(), ".md")),
				RelPath:     rel,
				HasExercise: fileExists(base + ".exercise.md"),
				HasCheck:    fileExists(base + ".check.sh"),
			}
			sec.Items = append(sec.Items, item)
		}
		sort.Slice(sec.Items, func(i, j int) bool { return sec.Items[i].RelPath < sec.Items[j].RelPath })
		if len(sec.Items) > 0 {
			built = append(built, sec)
		}
	}
	return built
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// safePathLinux validates that rel is within linux/ section directories
// and ends with .md, .exercise.md, or .check.sh.
func (s *server) safePathLinux(rel string) (string, error) {
	clean := filepath.Clean(rel)
	if strings.HasPrefix(clean, "..") || filepath.IsAbs(clean) {
		return "", fmt.Errorf("invalid path")
	}
	abs := filepath.Join(s.repoRoot, clean)
	relCheck, err := filepath.Rel(s.repoRoot, abs)
	if err != nil || strings.HasPrefix(relCheck, "..") {
		return "", fmt.Errorf("path escapes root")
	}
	slash := filepath.ToSlash(clean)
	allowed := false
	for _, d := range linuxSectionDirs {
		if strings.HasPrefix(slash, d+"/") {
			allowed = true
			break
		}
	}
	if !allowed {
		return "", fmt.Errorf("path not in a linux section")
	}
	ext := strings.ToLower(rel)
	if !strings.HasSuffix(ext, ".md") && !strings.HasSuffix(ext, ".check.sh") {
		return "", fmt.Errorf("only .md and .check.sh files")
	}
	return abs, nil
}

func (s *server) handleLinux(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/linux" {
		http.NotFound(w, r)
		return
	}
	sections := s.loadLinuxSections()
	tmpl, err := template.ParseFS(webFS, "web/linux.html")
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	if err := tmpl.Execute(w, sections); err != nil {
		log.Println(err)
	}
}

func (s *server) handleLinuxFile(w http.ResponseWriter, r *http.Request) {
	rel := r.URL.Query().Get("path")
	abs, err := s.safePathLinux(rel)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	notes, err := os.ReadFile(abs)
	if err != nil {
		http.Error(w, err.Error(), 404)
		return
	}

	base := filepath.Join(filepath.Dir(abs), strings.TrimSuffix(filepath.Base(abs), ".md"))
	exercise := ""
	if b, err := os.ReadFile(base + ".exercise.md"); err == nil {
		exercise = string(b)
	}
	hasCheck := fileExists(base + ".check.sh")

	_ = s.tracker.RecordOpen(r.Context(), analytics.SessionID(r), rel)
	writeJSON(w, map[string]any{
		"path":      rel,
		"notes":     string(notes),
		"exercise":  exercise,
		"has_check": hasCheck,
	})
}

func (s *server) handleLinuxCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST only", 405)
		return
	}
	if s.dockerMgr == nil {
		http.Error(w, "docker not available", 503)
		return
	}
	var req struct {
		Path string `json:"path"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), 400)
		return
	}
	// Validate the .md path, then derive the .check.sh path.
	mdAbs, err := s.safePathLinux(req.Path)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}
	base := strings.TrimSuffix(mdAbs, ".md")
	checkPath := base + ".check.sh"
	script, err := os.ReadFile(checkPath)
	if err != nil {
		http.Error(w, "no check script for this lesson", 404)
		return
	}

	sid := analytics.SessionID(r)
	containerID, err := s.dockerMgr.GetOrCreate(r.Context(), sid)
	if err != nil {
		http.Error(w, "container error: "+err.Error(), 503)
		return
	}

	result, err := s.dockerMgr.ExecCheck(r.Context(), containerID, script)
	if err != nil {
		http.Error(w, "check error: "+err.Error(), 500)
		return
	}

	_ = s.completions.RecordCheck(r.Context(), sid, req.Path, analytics.SectionFromPath(req.Path), result.Passed)
	_ = s.tracker.RecordRun(r.Context(), sid, req.Path, 0, result.Passed)

	writeJSON(w, map[string]any{
		"passed": result.Passed,
		"output": result.Output,
	})
}

func (s *server) handleLinuxTerminalWS(w http.ResponseWriter, r *http.Request) {
	if s.dockerMgr == nil {
		http.Error(w, "docker not available", 503)
		return
	}
	c, err := websocket.Accept(w, r, &websocket.AcceptOptions{
		InsecureSkipVerify: true,
	})
	if err != nil {
		log.Println("linux ws accept:", err)
		return
	}
	sid := analytics.SessionID(r)
	s.dockerMgr.HandleTerminal(r.Context(), c, sid)
}

// handleLinuxCompletions returns the set of lesson paths the current session
// has passed at least once.
func (s *server) handleLinuxCompletions(w http.ResponseWriter, r *http.Request) {
	sid := analytics.SessionID(r)
	paths, err := s.completions.CompletedPaths(r.Context(), sid)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	if paths == nil {
		paths = []string{}
	}
	writeJSON(w, map[string]any{"completed": paths})
}

// handleLinuxStatus returns Docker image readiness and build state.
func (s *server) handleLinuxStatus(w http.ResponseWriter, r *http.Request) {
	if s.dockerMgr == nil {
		writeJSON(w, map[string]any{"image_ready": false, "building": false, "image": "", "docker_available": false})
		return
	}
	st := s.dockerMgr.Status()
	writeJSON(w, map[string]any{
		"image_ready":      st.ImageReady,
		"building":         st.Building,
		"image":            st.Image,
		"docker_available": true,
		"error":            st.Error,
	})
}

// handleLinuxStats returns aggregated stats for the dashboard.
func (s *server) handleLinuxStats(w http.ResponseWriter, r *http.Request) {
	sid := analytics.SessionID(r)
	q := s.tracker.Queries()

	overall, _ := q.OverallStats(r.Context())
	sections, _ := q.SectionTotals(r.Context())
	lessons, _ := q.LessonTotals(r.Context())
	weekly, _ := s.completions.WeeklyStats(r.Context(), sid)
	completed, _ := s.completions.CompletedPaths(r.Context(), sid)

	if weekly == nil {
		weekly = []db.WeekStat{}
	}
	if completed == nil {
		completed = []string{}
	}

	writeJSON(w, map[string]any{
		"overall": map[string]any{
			"sessions":      overall.Sessions,
			"opens":         overall.Opens,
			"total_seconds": coerceInt64(overall.TotalSeconds),
			"checks_run":    overall.CodeRuns,
			"checks_passed": overall.SuccessfulRuns,
			"exercises_done": len(completed),
		},
		"sections": sectionsToMaps(sections),
		"lessons":  lessonsToMaps(lessons),
		"weekly":   weekly,
	})
}

// handleLinuxProgress returns weekly completion stats for the progress view.
func (s *server) handleLinuxProgress(w http.ResponseWriter, r *http.Request) {
	sid := analytics.SessionID(r)
	weekly, err := s.completions.WeeklyStats(r.Context(), sid)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	if weekly == nil {
		weekly = []db.WeekStat{}
	}
	writeJSON(w, map[string]any{"weekly": weekly})
}


func coerceInt64(v any) int64 {
	switch x := v.(type) {
	case int64:
		return x
	case float64:
		return int64(x)
	default:
		return 0
	}
}

func sectionsToMaps(rows []store.SectionTotalsRow) []map[string]any {
	out := make([]map[string]any, 0, len(rows))
	for _, r := range rows {
		out = append(out, map[string]any{
			"section":       r.Section,
			"opens":         r.Opens,
			"total_seconds": coerceInt64(r.TotalSeconds),
			"checks_run":    r.CodeRuns,
		})
	}
	return out
}

func lessonsToMaps(rows []store.LessonTotalsRow) []map[string]any {
	out := make([]map[string]any, 0, len(rows))
	for _, r := range rows {
		out = append(out, map[string]any{
			"lesson_path":   r.LessonPath,
			"section":       r.Section,
			"opens":         r.Opens,
			"total_seconds": coerceInt64(r.TotalSeconds),
			"checks_run":    r.CodeRuns,
		})
	}
	return out
}
