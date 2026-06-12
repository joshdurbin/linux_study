package docker

import (
	"archive/tar"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/filters"
	dockerimage "github.com/docker/docker/api/types/image"
	dockertypes "github.com/docker/docker/api/types"
	dockerclient "github.com/docker/docker/client"
	"github.com/docker/docker/pkg/stdcopy"
)

const (
	StudyImage        = "linux-study:latest"
	FallbackImage     = "ubuntu:24.04"
	containerPrefix   = "linux-study-"
	inactivityTimeout = 30 * time.Minute
)

var pidsLimit int64 = 256

type Manager struct {
	cli  *dockerclient.Client
	mu   sync.Mutex // guards image/user/home/sessions
	image string
	user  string
	home  string
	sessions map[string]*sessionEntry

	buildMu  sync.Mutex // guards build state
	building bool
	buildErr error
	imageOK  bool // true once StudyImage is confirmed present
}

type sessionEntry struct {
	containerID string
	lastUsed    time.Time
}

// BuildStatus returns current image build state.
type BuildStatus struct {
	ImageReady bool   `json:"image_ready"`
	Building   bool   `json:"building"`
	Image      string `json:"image"`
	Error      string `json:"error,omitempty"`
}

func NewManager(ctx context.Context) (*Manager, error) {
	cli, err := dockerclient.NewClientWithOpts(
		dockerclient.FromEnv,
		dockerclient.WithAPIVersionNegotiation(),
	)
	if err != nil {
		return nil, fmt.Errorf("docker client: %w", err)
	}

	m := &Manager{
		cli:      cli,
		image:    FallbackImage,
		user:     "root",
		home:     "/root",
		sessions: make(map[string]*sessionEntry),
	}

	images, err := cli.ImageList(ctx, dockerimage.ListOptions{
		Filters: filters.NewArgs(filters.Arg("reference", StudyImage)),
	})
	if err == nil && len(images) > 0 {
		m.image = StudyImage
		m.user = "student"
		m.home = "/home/student"
		m.imageOK = true
		log.Printf("docker: using study image %s", StudyImage)
	} else {
		log.Printf("docker: %s not found — using %s fallback; call BuildStudyImage() to build it", StudyImage, FallbackImage)
	}

	go m.cleanupLoop(context.Background())
	return m, nil
}

// Status returns the current image/build state for the status API.
func (m *Manager) Status() BuildStatus {
	m.buildMu.Lock()
	defer m.buildMu.Unlock()
	m.mu.Lock()
	img := m.image
	ok := m.imageOK
	m.mu.Unlock()
	s := BuildStatus{ImageReady: ok, Building: m.building, Image: img}
	if m.buildErr != nil {
		s.Error = m.buildErr.Error()
	}
	return s
}

// BuildStudyImage builds linux-study:latest from the provided Dockerfile content.
// The build runs in the background. Progress is logged. Status() reflects completion.
func (m *Manager) BuildStudyImage(ctx context.Context, dockerfileContent []byte) {
	m.buildMu.Lock()
	if m.building || m.imageOK {
		m.buildMu.Unlock()
		return
	}
	m.building = true
	m.buildErr = nil
	m.buildMu.Unlock()

	go func() {
		log.Printf("docker: building %s (this may take a few minutes)…", StudyImage)
		err := m.doBuildImage(ctx, dockerfileContent)

		m.buildMu.Lock()
		m.building = false
		m.buildErr = err
		m.buildMu.Unlock()

		if err != nil {
			log.Printf("docker: image build failed: %v", err)
			return
		}

		m.mu.Lock()
		m.image = StudyImage
		m.user = "student"
		m.home = "/home/student"
		m.imageOK = true
		m.mu.Unlock()

		log.Printf("docker: %s ready — new sessions will use the study image", StudyImage)
	}()
}

func (m *Manager) doBuildImage(ctx context.Context, dockerfile []byte) error {
	// Build a minimal tar archive containing only the Dockerfile.
	var buf bytes.Buffer
	tw := tar.NewWriter(&buf)
	if err := tw.WriteHeader(&tar.Header{
		Name:     "Dockerfile",
		Size:     int64(len(dockerfile)),
		Mode:     0644,
		Typeflag: tar.TypeReg,
	}); err != nil {
		return err
	}
	if _, err := tw.Write(dockerfile); err != nil {
		return err
	}
	if err := tw.Close(); err != nil {
		return err
	}

	resp, err := m.cli.ImageBuild(ctx, &buf, dockertypes.ImageBuildOptions{
		Tags:        []string{StudyImage},
		Dockerfile:  "Dockerfile",
		Remove:      true,
		ForceRemove: true,
		PullParent:  true,
	})
	if err != nil {
		return fmt.Errorf("image build API: %w", err)
	}
	defer resp.Body.Close()

	dec := json.NewDecoder(resp.Body)
	for {
		var msg struct {
			Stream string `json:"stream"`
			Error  string `json:"error"`
		}
		if err := dec.Decode(&msg); err != nil {
			if err == io.EOF {
				break
			}
			return fmt.Errorf("reading build output: %w", err)
		}
		if msg.Error != "" {
			return fmt.Errorf("%s", strings.TrimSpace(msg.Error))
		}
		if s := strings.TrimRight(msg.Stream, "\r\n"); s != "" {
			log.Printf("build | %s", s)
		}
	}
	return nil
}

// GetOrCreate returns the container ID for the given session, creating it if needed.
func (m *Manager) GetOrCreate(ctx context.Context, sessionID string) (string, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if e, ok := m.sessions[sessionID]; ok {
		info, err := m.cli.ContainerInspect(ctx, e.containerID)
		if err == nil && info.State.Running {
			// Replace containers whose privileged setting no longer matches.
			// This handles the transition from unprivileged → privileged after
			// rebuilding the study image.
			if info.HostConfig.Privileged != m.imageOK {
				log.Printf("docker: replacing stale container %s (privileged mismatch)", e.containerID[:12])
				_ = m.cli.ContainerRemove(ctx, e.containerID, container.RemoveOptions{Force: true})
			} else {
				e.lastUsed = time.Now()
				return e.containerID, nil
			}
		}
		delete(m.sessions, sessionID)
	}

	cid, err := m.createContainer(ctx, sessionID)
	if err != nil {
		return "", err
	}
	m.sessions[sessionID] = &sessionEntry{containerID: cid, lastUsed: time.Now()}
	return cid, nil
}

func (m *Manager) createContainer(ctx context.Context, sessionID string) (string, error) {
	shortID := sessionID
	if len(shortID) > 12 {
		shortID = shortID[:12]
	}
	name := containerPrefix + shortID

	_ = m.cli.ContainerRemove(ctx, name, container.RemoveOptions{Force: true})

	// When using the study image (systemd as PID 1) we need privileged mode and
	// host cgroup namespace so systemctl/journalctl work. The fallback ubuntu
	// image uses plain bash as PID 1 and doesn't need these.
	privileged := m.imageOK
	cgroupns := container.CgroupnsMode("private")
	if privileged {
		cgroupns = "host"
	}

	cfg := &container.Config{
		// Study image: systemd is CMD/PID 1, exec sessions land inside it.
		// Fallback image: bash is PID 1 (no systemd).
		Image:     m.image,
		Tty:       true,
		OpenStdin: true,
		StdinOnce: false,
		Env:       []string{"TERM=xterm-256color", "HOME=" + m.home, "LANG=en_US.UTF-8"},
	}

	hc := &container.HostConfig{
		AutoRemove:   false,
		Privileged:   privileged,
		CgroupnsMode: cgroupns,
		Tmpfs: map[string]string{
			"/run":      "rw,nosuid,nodev",
			"/run/lock": "rw,nosuid,nodev",
			"/tmp":      "rw,nosuid,nodev",
		},
		Resources: container.Resources{
			Memory:    1024 * 1024 * 1024, // 1GB — systemd needs more headroom
			NanoCPUs:  2_000_000_000,      // 2 CPUs
			PidsLimit: &pidsLimit,
		},
	}

	resp, err := m.cli.ContainerCreate(ctx, cfg, hc, nil, nil, name)
	if err != nil {
		return "", fmt.Errorf("container create: %w", err)
	}

	if err := m.cli.ContainerStart(ctx, resp.ID, container.StartOptions{}); err != nil {
		_ = m.cli.ContainerRemove(ctx, resp.ID, container.RemoveOptions{Force: true})
		return "", fmt.Errorf("container start: %w", err)
	}

	// When systemd is PID 1, wait for it to signal readiness before accepting
	// exec sessions. We poll the systemd state via a quick exec; give up after
	// 10s so a failed systemd start doesn't block the user forever.
	if privileged {
		if err := m.waitForSystemd(ctx, resp.ID); err != nil {
			log.Printf("docker: systemd not ready in %s: %v (exec sessions may still work)", resp.ID[:12], err)
		}
	}

	log.Printf("docker: started container %s (image=%s session=%s)", resp.ID[:12], m.image, sessionID[:8])
	return resp.ID, nil
}

// waitForSystemd polls until `systemctl is-system-running` exits 0 or timeout.
func (m *Manager) waitForSystemd(ctx context.Context, containerID string) error {
	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		exec, err := m.cli.ContainerExecCreate(ctx, containerID, container.ExecOptions{
			Cmd:          []string{"systemctl", "is-system-running"},
			AttachStdout: true,
			AttachStderr: true,
		})
		if err != nil {
			time.Sleep(200 * time.Millisecond)
			continue
		}
		attach, err := m.cli.ContainerExecAttach(ctx, exec.ID, container.ExecAttachOptions{})
		if err != nil {
			time.Sleep(200 * time.Millisecond)
			continue
		}
		attach.Close()
		inspect, err := m.cli.ContainerExecInspect(ctx, exec.ID)
		if err == nil && inspect.ExitCode == 0 {
			return nil
		}
		time.Sleep(300 * time.Millisecond)
	}
	return fmt.Errorf("timed out after 10s")
}

// CheckResult holds the output and pass/fail from running a check script.
type CheckResult struct {
	Output string
	Passed bool
}

// ExecCheck runs a shell script (as stdin) inside the container and returns the result.
func (m *Manager) ExecCheck(ctx context.Context, containerID string, script []byte) (CheckResult, error) {
	execResp, err := m.cli.ContainerExecCreate(ctx, containerID, container.ExecOptions{
		AttachStdin:  true,
		AttachStdout: true,
		AttachStderr: true,
		Tty:          false,
		Cmd:          []string{"/bin/bash", "-s"},
	})
	if err != nil {
		return CheckResult{}, fmt.Errorf("exec create: %w", err)
	}

	attach, err := m.cli.ContainerExecAttach(ctx, execResp.ID, container.ExecAttachOptions{})
	if err != nil {
		return CheckResult{}, fmt.Errorf("exec attach: %w", err)
	}
	defer attach.Close()

	go func() {
		attach.Conn.Write(script)
		attach.CloseWrite()
	}()

	var stdout, stderr strings.Builder
	if _, err := stdcopy.StdCopy(&stdout, &stderr, attach.Reader); err != nil && !strings.Contains(err.Error(), "EOF") {
		log.Printf("docker: stdcopy: %v", err)
	}

	inspect, err := m.cli.ContainerExecInspect(ctx, execResp.ID)
	if err != nil {
		return CheckResult{}, fmt.Errorf("exec inspect: %w", err)
	}

	combined := stdout.String()
	if s := strings.TrimSpace(stderr.String()); s != "" {
		combined += "\n" + s
	}
	return CheckResult{
		Output: strings.TrimSpace(combined),
		Passed: inspect.ExitCode == 0,
	}, nil
}

// Shutdown stops and removes all managed containers.
func (m *Manager) Shutdown(ctx context.Context) {
	m.mu.Lock()
	ids := make([]string, 0, len(m.sessions))
	for _, e := range m.sessions {
		ids = append(ids, e.containerID)
	}
	m.sessions = make(map[string]*sessionEntry)
	m.mu.Unlock()

	for _, cid := range ids {
		_ = m.cli.ContainerRemove(ctx, cid, container.RemoveOptions{Force: true})
	}
	m.cli.Close()
}

func (m *Manager) cleanupLoop(ctx context.Context) {
	t := time.NewTicker(5 * time.Minute)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			m.doCleanup(ctx)
		}
	}
}

func (m *Manager) doCleanup(ctx context.Context) {
	m.mu.Lock()
	var stale []string
	for sid, e := range m.sessions {
		if time.Since(e.lastUsed) > inactivityTimeout {
			stale = append(stale, e.containerID)
			delete(m.sessions, sid)
		}
	}
	m.mu.Unlock()

	for _, cid := range stale {
		if err := m.cli.ContainerRemove(ctx, cid, container.RemoveOptions{Force: true}); err != nil {
			log.Printf("docker: cleanup remove %s: %v", cid[:12], err)
		} else {
			log.Printf("docker: removed idle container %s", cid[:12])
		}
	}
}
