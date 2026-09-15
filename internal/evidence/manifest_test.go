package evidence

import (
	"os"
	"path/filepath"
	"testing"
)

func TestManifestAndVerify(t *testing.T) {
	root := t.TempDir()
	if err := os.WriteFile(filepath.Join(root, "evidence.txt"), []byte("immutable evidence\n"), 0600); err != nil { t.Fatal(err) }
	manifest, err := Manifest(root, []string{"evidence.txt"})
	if err != nil { t.Fatal(err) }
	if err := Verify(root, manifest); err != nil { t.Fatalf("verify: %v", err) }
	if err := os.WriteFile(filepath.Join(root, "evidence.txt"), []byte("tampered\n"), 0600); err != nil { t.Fatal(err) }
	if err := Verify(root, manifest); err == nil { t.Fatal("expected tampering to be detected") }
}
