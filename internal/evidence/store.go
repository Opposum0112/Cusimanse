package evidence

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Record is immutable research evidence. It is deliberately separate from
// agent reasoning and memory so findings can be independently verified.
type Record struct {
	ID         string            `json:"id"`
	SessionID  string            `json:"session_id"`
	RunID      string            `json:"run_id"`
	Source     string            `json:"source"`
	Kind       string            `json:"kind"`
	ObservedAt time.Time         `json:"observed_at"`
	Content    string            `json:"content"`
	Metadata   map[string]string `json:"metadata,omitempty"`
	Digest     string            `json:"digest"`
}

type Store struct {
	dir string
	mu  sync.Mutex
}

func New(dir string) (*Store, error) {
	if dir == "" { return nil, fmt.Errorf("evidence directory is required") }
	if err := os.MkdirAll(dir, 0700); err != nil { return nil, err }
	return &Store{dir: dir}, nil
}

func NewID(sessionID, runID, source, kind, content string) string {
	sum := sha256.Sum256([]byte(sessionID + "\x00" + runID + "\x00" + source + "\x00" + kind + "\x00" + content))
	return hex.EncodeToString(sum[:])
}

func (s *Store) Put(r Record) error {
	s.mu.Lock(); defer s.mu.Unlock()
	if r.ID == "" { return fmt.Errorf("evidence ID is required") }
	if r.Content == "" { return fmt.Errorf("evidence content is required") }
	if r.ObservedAt.IsZero() { r.ObservedAt = time.Now().UTC() }
	if r.Digest == "" {
		sum := sha256.Sum256([]byte(r.Content))
		r.Digest = hex.EncodeToString(sum[:])
	}
	b, err := json.MarshalIndent(r, "", "  ")
	if err != nil { return err }
	path := filepath.Join(s.dir, r.ID+".json")
	if _, err := os.Stat(path); err == nil { return fmt.Errorf("evidence %q already exists", r.ID) }
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, b, 0600); err != nil { return err }
	if err := os.Rename(tmp, path); err != nil { _ = os.Remove(tmp); return err }
	return nil
}

func (s *Store) Get(id string) (Record, error) {
	s.mu.Lock(); defer s.mu.Unlock()
	if id == "" { return Record{}, fmt.Errorf("evidence ID is required") }
	b, err := os.ReadFile(filepath.Join(s.dir, id+".json"))
	if err != nil { return Record{}, err }
	var r Record
	if err := json.Unmarshal(b, &r); err != nil { return Record{}, err }
	return r, nil
}
