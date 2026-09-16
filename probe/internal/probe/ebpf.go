package probe

// EBPFCollector is the data-plane SPI for kernel telemetry.
// Platform-specific implementations can attach eBPF programs without coupling
// the control plane to a particular kernel tracing library.
type EBPFCollector interface {
	Start() error
	Stop() error
	Events() <-chan Event
}
