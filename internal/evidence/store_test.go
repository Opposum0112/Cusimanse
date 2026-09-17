package evidence

import (
	"path/filepath"
	"testing"
)

func TestStorePutGetAndImmutability(t *testing.T) {
	dir := t.TempDir()
	s, err := New(filepath.Join(dir, "evidence"))
	if err != nil { t.Fatal(err) }
	r := Record{ID: NewID("s1", "r1", "fixture", "observation", "hello"), SessionID: "s1", RunID: "r1", Source: "fixture", Kind: "observation", Content: "hello"}
	if err := s.Put(r); err != nil { t.Fatal(err) }
	got, err := s.Get(r.ID)
	if err != nil { t.Fatal(err) }
	if got.Content != r.Content || got.Digest == "" { t.Fatalf("unexpected record: %+v", got) }
	if err := s.Put(r); err == nil { t.Fatal("expected duplicate evidence to be rejected") }
}

func TestNewIDDeterministic(t *testing.T) {
	a := NewID("s", "r", "src", "obs", "content")
	b := NewID("s", "r", "src", "obs", "content")
	if a == "" || a != b { t.Fatalf("IDs are not deterministic: %q %q", a, b) }
}
