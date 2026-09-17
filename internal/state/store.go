package state

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Record is the durable Cusimanse execution envelope. ADK session state is the
// workflow scratchpad; this journal is the crash-safe recovery/audit record.
type Record struct {
	SessionID string         `json:"session_id"`
	RunID     string         `json:"run_id"`
	Phase     string         `json:"phase"`
	Status    string         `json:"status"`
	UpdatedAt time.Time      `json:"updated_at"`
	State     map[string]any `json:"state,omitempty"`
}

type Store struct { dir string; mu sync.Mutex }

func New(dir string) (*Store, error) {
	if dir == "" { return nil, fmt.Errorf("state directory is required") }
	if err := os.MkdirAll(dir, 0700); err != nil { return nil, err }
	return &Store{dir: dir}, nil
}

func (s *Store) path(sessionID string) string { return filepath.Join(s.dir, sessionID+".json") }

// Save atomically replaces the latest durable snapshot for a session.
func (s *Store) Save(r Record) error {
	s.mu.Lock(); defer s.mu.Unlock()
	if r.SessionID == "" { return fmt.Errorf("session ID is required") }
	r.UpdatedAt = time.Now().UTC()
	b, err := json.MarshalIndent(r, "", "  ")
	if err != nil { return err }
	tmp := s.path(r.SessionID) + ".tmp"
	if err := os.WriteFile(tmp, b, 0600); err != nil { return err }
	if err := os.Rename(tmp, s.path(r.SessionID)); err != nil { return err }
	return nil
}

func (s *Store) Load(sessionID string) (Record, error) {
	s.mu.Lock(); defer s.mu.Unlock()
	if sessionID == "" { return Record{}, fmt.Errorf("session ID is required") }
	b, err := os.ReadFile(s.path(sessionID))
	if err != nil { return Record{}, err }
	var r Record
	if err := json.Unmarshal(b, &r); err != nil { return Record{}, err }
	return r, nil
}
