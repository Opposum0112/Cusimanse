package execution

import (
	"testing"
)

func TestOperationIDIsDeterministic(t *testing.T) {
	a := OperationID("s", "r", "cap", map[string]string{"b": "2", "a": "1"})
	b := OperationID("s", "r", "cap", map[string]string{"b": "2", "a": "1"})
	if a == "" || a != b { t.Fatalf("operation ID is not deterministic: %q %q", a, b) }
}

func TestJournalLifecycle(t *testing.T) {
	j, err := New(t.TempDir())
	if err != nil { t.Fatal(err) }
	id := OperationID("s", "r", "cap", nil)
	if err := j.Put(Entry{OperationID: id, SessionID: "s", RunID: "r", Capability: "cap", RequestHash: id, Status: Pending}); err != nil { t.Fatal(err) }
	if _, err := j.Update(id, Running, "started"); err != nil { t.Fatal(err) }
	got, err := j.Update(id, Completed, "done")
	if err != nil { t.Fatal(err) }
	if got.Status != Completed || got.Message != "done" { t.Fatalf("unexpected entry: %+v", got) }
	loaded, err := j.Get(id)
	if err != nil { t.Fatal(err) }
	if loaded.OperationID != id || loaded.Status != Completed { t.Fatalf("unexpected persisted entry: %+v", loaded) }
}

func TestJournalRejectsMissingID(t *testing.T) {
	j, err := New(t.TempDir())
	if err != nil { t.Fatal(err) }
	if err := j.Put(Entry{}); err == nil { t.Fatal("expected missing operation ID error") }
}
