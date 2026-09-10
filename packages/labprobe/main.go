// labprobe is a harmless observation target for experiment go-install-001.
// It prints a JSON snapshot of the local Go environment and does not open
// network connections.
package main

import (
	"encoding/json"
	"os"
	"runtime"
	"time"
)

const Version = "0.1.0"

func main() {
	hostname, _ := os.Hostname()
	cwd, _ := os.Getwd()
	report := map[string]any{
		"name":       "labprobe",
		"version":    Version,
		"goos":       runtime.GOOS,
		"goarch":     runtime.GOARCH,
		"compiler":   runtime.Compiler,
		"num_cpu":    runtime.NumCPU(),
		"time_utc":   time.Now().UTC().Format(time.RFC3339),
		"hostname":   hostname,
		"cwd":        cwd,
		"gopath":     os.Getenv("GOPATH"),
		"gocache":    os.Getenv("GOCACHE"),
		"gomodcache": os.Getenv("GOMODCACHE"),
		"goproxy":    os.Getenv("GOPROXY"),
		"args":       os.Args,
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	if err := enc.Encode(report); err != nil {
		os.Exit(1)
	}
}
