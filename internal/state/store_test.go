package state

import (
	"path/filepath"
	"testing"
)

func TestStoreRoundTrip(t *testing.T) {
	dir := t.TempDir()
	s, err := New(filepath.Join(dir, "state"))
	if err != nil { t.Fatal(err) }
	want := Record{SessionID: "s1", RunID: "r1", Phase: "verify", Status: "RUNNING", State: map[string]any{"attempt": float64(2)}}
	if err := s.Save(want); err != nil { t.Fatal(err) }
	got, err := s.Load("s1")
	if err != nil { t.Fatal(err) }
	if got.SessionID != want.SessionID || got.RunID != want.RunID || got.Phase != want.Phase || got.Status != want.Status { t.Fatalf("round trip mismatch: %#v", got) }
	if got.UpdatedAt.IsZero() { t.Fatal("expected durable timestamp") }
}
