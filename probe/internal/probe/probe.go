package probe

import (
	"encoding/json"
	"fmt"
	"os"
	"runtime"
	"time"
)

type Capability string

const (
	CapabilityPreflight Capability = "preflight.verify"
	CapabilityProcess  Capability = "telemetry.process"
	CapabilityNetwork  Capability = "telemetry.network"
	CapabilitySyscall  Capability = "telemetry.syscall"
)

type Event struct {
	Timestamp time.Time         `json:"timestamp"`
	Kind      string             `json:"kind"`
	Payload   map[string]any     `json:"payload"`
}

func Preflight() Event {
	return Event{Timestamp: time.Now().UTC(), Kind: string(CapabilityPreflight), Payload: map[string]any{
		"os": runtime.GOOS, "arch": runtime.GOARCH, "uid": os.Getuid(),
	}}
}

func EncodeEvent(event Event) ([]byte, error) {
	return json.Marshal(event)
}

func ValidateCapability(value string) error {
	switch Capability(value) {
	case CapabilityPreflight, CapabilityProcess, CapabilityNetwork, CapabilitySyscall:
		return nil
	default:
		return fmt.Errorf("unsupported labprobe capability: %s", value)
	}
}
