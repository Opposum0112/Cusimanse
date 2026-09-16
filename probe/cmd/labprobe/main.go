package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/Opposum0112/Cusimanse/probe/internal/probe"
)

func main() {
	interval := flag.Duration("interval", time.Second, "telemetry heartbeat interval")
	flag.Parse()

	if err := probe.ValidateCapability(string(probe.CapabilityPreflight)); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}

	event, err := probe.EncodeEvent(probe.Preflight())
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	fmt.Println(string(event))

	ticker := time.NewTicker(*interval)
	defer ticker.Stop()
	for range ticker.C {
		event, err := probe.EncodeEvent(probe.Event{
			Timestamp: time.Now().UTC(),
			Kind:      string(probe.CapabilityProcess),
			Payload:   map[string]any{"status": "heartbeat"},
		})
		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
		fmt.Println(string(event))
	}
}
