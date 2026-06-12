package docker

import (
	"context"
	"encoding/json"
	"io"
	"log"
	"time"

	"github.com/coder/websocket"
	"github.com/docker/docker/api/types/container"
	"golang.org/x/sync/errgroup"
)

const (
	initialRows = 50
	initialCols = 220
)

// HandleTerminal relays PTY I/O between an already-accepted WebSocket connection
// and a bash exec inside the container for sessionID.
//
// Protocol (client → server):
//   - binary frames  → stdin bytes sent to container
//   - text frames    → JSON control: {"type":"resize","rows":N,"cols":N}
//
// Protocol (server → client):
//   - binary frames  → raw stdout/stderr from the container TTY
func (m *Manager) HandleTerminal(baseCtx context.Context, wsConn *websocket.Conn, sessionID string) {
	// errgroup gives us a shared context that is cancelled as soon as either
	// goroutine returns (whether cleanly or with an error).
	g, ctx := errgroup.WithContext(baseCtx)

	containerID, err := m.GetOrCreate(baseCtx, sessionID)
	if err != nil {
		log.Printf("terminal: get container for session %s: %v", sessionID[:8], err)
		wsConn.Close(websocket.StatusInternalError, "container unavailable")
		return
	}

	execID, err := m.cli.ContainerExecCreate(baseCtx, containerID, container.ExecOptions{
		AttachStdin:  true,
		AttachStdout: true,
		AttachStderr: true,
		Tty:          true,
		Cmd:          []string{"/bin/bash", "-l"},
		Env:          []string{"TERM=xterm-256color"},
		User:         m.user,
		WorkingDir:   m.home,
	})
	if err != nil {
		log.Printf("terminal: exec create: %v", err)
		wsConn.Close(websocket.StatusInternalError, "exec failed")
		return
	}

	attach, err := m.cli.ContainerExecAttach(baseCtx, execID.ID, container.ExecAttachOptions{Tty: true})
	if err != nil {
		log.Printf("terminal: exec attach: %v", err)
		wsConn.Close(websocket.StatusInternalError, "attach failed")
		return
	}
	defer attach.Close()

	// When the errgroup context is done (either goroutine exits), close the
	// Docker attach so the Reader.Read in the first goroutine unblocks.
	// context.AfterFunc is non-blocking and runs in its own goroutine.
	context.AfterFunc(ctx, attach.Close)

	_ = m.cli.ContainerExecResize(baseCtx, execID.ID, container.ResizeOptions{
		Height: initialRows,
		Width:  initialCols,
	})

	m.mu.Lock()
	if e, ok := m.sessions[sessionID]; ok {
		e.lastUsed = time.Now()
	}
	m.mu.Unlock()

	// Goroutine 1: Docker stdout/stderr → WebSocket binary frames.
	g.Go(func() error {
		buf := make([]byte, 4096)
		for {
			n, err := attach.Reader.Read(buf)
			if n > 0 {
				if werr := wsConn.Write(ctx, websocket.MessageBinary, buf[:n]); werr != nil {
					return werr
				}
			}
			if err != nil {
				if err == io.EOF {
					return nil
				}
				return err
			}
		}
	})

	// Goroutine 2: WebSocket → Docker stdin / resize.
	g.Go(func() error {
		for {
			msgType, data, err := wsConn.Read(ctx)
			if err != nil {
				return err
			}
			switch msgType {
			case websocket.MessageBinary:
				if _, err := attach.Conn.Write(data); err != nil {
					return err
				}
			case websocket.MessageText:
				var msg struct {
					Type string `json:"type"`
					Rows uint   `json:"rows"`
					Cols uint   `json:"cols"`
				}
				if json.Unmarshal(data, &msg) == nil && msg.Type == "resize" && msg.Rows > 0 && msg.Cols > 0 {
					_ = m.cli.ContainerExecResize(ctx, execID.ID, container.ResizeOptions{
						Height: msg.Rows,
						Width:  msg.Cols,
					})
				}
			}
		}
	})

	if err := g.Wait(); err != nil && ctx.Err() == nil {
		log.Printf("terminal: session %s: %v", sessionID[:8], err)
	}
	wsConn.Close(websocket.StatusNormalClosure, "")
}
