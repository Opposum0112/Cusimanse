package evidence

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
)

func HashFile(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil { return "", err }
	defer f.Close()
	h := sha256.New()
	if _, err := io.Copy(h, f); err != nil { return "", err }
	return hex.EncodeToString(h.Sum(nil)), nil
}

func Manifest(root string, files []string) (string, error) {
	files = append([]string(nil), files...)
	sort.Strings(files)
	out := ""
	for _, rel := range files {
		path := filepath.Join(root, rel)
		hash, err := HashFile(path)
		if err != nil { return "", fmt.Errorf("hash %s: %w", rel, err) }
		out += hash + "  " + filepath.ToSlash(rel) + "\n"
	}
	return out, nil
}

func Verify(root, manifest string) error {
	for _, line := range splitLines(manifest) {
		if line == "" { continue }
		var expected, rel string
		if _, err := fmt.Sscanf(line, "%64s  %s", &expected, &rel); err != nil { return fmt.Errorf("invalid manifest line: %q", line) }
		actual, err := HashFile(filepath.Join(root, rel))
		if err != nil { return err }
		if actual != expected { return fmt.Errorf("evidence hash mismatch: %s", rel) }
	}
	return nil
}

func splitLines(s string) []string {
	var lines []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' { lines = append(lines, s[start:i]); start = i + 1 }
	}
	if start < len(s) { lines = append(lines, s[start:]) }
	return lines
}
