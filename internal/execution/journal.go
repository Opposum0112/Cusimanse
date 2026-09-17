package execution

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

type Status string

const (
	Pending Status = "PENDING"
	Running Status = "RUNNING"
	Completed Status = "COMPLETED"
	Failed Status = "FAILED"
	AmbiguousEffect Status = "AMBIGUOUS_EFFECT"
)

type Entry struct {
	OperationID string            `json:"operation_id"`
	SessionID   string            `json:"session_id"`
	RunID       string            `json:"run_id"`
	Capability  string            `json:"capability"`
	RequestHash string            `json:"request_hash"`
	Status      Status            `json:"status"`
	Message     string            `json:"message,omitempty"`
	StartedAt   time.Time         `json:"started_at"`
	UpdatedAt   time.Time         `json:"updated_at"`
	Metadata    map[string]string `json:"metadata,omitempty"`
}

type Journal struct { dir string; mu sync.Mutex }

func New(dir string) (*Journal, error) {
	if dir == "" { return nil, fmt.Errorf("journal directory is required") }
	if err := os.MkdirAll(dir, 0700); err != nil { return nil, err }
	return &Journal{dir: dir}, nil
}

func OperationID(sessionID, runID, capability string, parameters map[string]string) string {
	b, _ := json.Marshal(struct {
		SessionID string `json:"session_id"`
		RunID string `json:"run_id"`
		Capability string `json:"capability"`
		Parameters map[string]string `json:"parameters,omitempty"`
	}{sessionID, runID, capability, parameters})
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

func (j *Journal) path(id string) string { return filepath.Join(j.dir, id+".json") }

func (j *Journal) Put(e Entry) error {
	j.mu.Lock(); defer j.mu.Unlock()
	if e.OperationID == "" { return fmt.Errorf("operation ID is required") }
	now := time.Now().UTC()
	if e.StartedAt.IsZero() { e.StartedAt = now }
	e.UpdatedAt = now
	return j.write(e)
}

func (j *Journal) Get(id string) (Entry, error) {
	j.mu.Lock(); defer j.mu.Unlock()
	if id == "" { return Entry{}, fmt.Errorf("operation ID is required") }
	return j.read(id)
}

func (j *Journal) Update(id string, status Status, message string) (Entry, error) {
	j.mu.Lock(); defer j.mu.Unlock()
	e, err := j.read(id)
	if err != nil { return Entry{}, err }
	e.Status, e.Message, e.UpdatedAt = status, message, time.Now().UTC()
	if err := j.write(e); err != nil { return Entry{}, err }
	return e, nil
}

func (j *Journal) read(id string) (Entry, error) {
	b, err := os.ReadFile(j.path(id))
	if err != nil { return Entry{}, err }
	var e Entry
	if err := json.Unmarshal(b, &e); err != nil { return Entry{}, err }
	return e, nil
}

func (j *Journal) write(e Entry) error {
	b, err := json.MarshalIndent(e, "", "  ")
	if err != nil { return err }
	tmp := j.path(e.OperationID) + ".tmp"
	if err := os.WriteFile(tmp, b, 0600); err != nil { return err }
	return os.Rename(tmp, j.path(e.OperationID))
}
