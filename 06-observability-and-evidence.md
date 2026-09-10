# 06 — Observability and Evidence

## Two observability domains

### AI observability

Tracks the agent system:

- model
- provider
- token use
- latency
- prompt/tool spans
- routing
- errors
- retries
- agent handoffs

Stack:

```text
OpenTelemetry
OpenInference
Phoenix
```

### Experiment observability

Tracks the workload:

- processes
- syscalls
- files
- DNS
- sockets
- packets
- HTTP/TLS metadata
- security events

Stack:

```text
strace
lsof
bpftrace
BCC
Tetragon
Sysdig
tcpdump
tshark
Zeek
Suricata
mitmproxy
```

## Evidence lifecycle

```text
Raw capture
   ↓
Immutable preservation
   ↓
Hash
   ↓
Deterministic reduction
   ↓
LLM analysis
   ↓
Finding
   ↓
Independent verification
   ↓
Report
```

## Data formats

Use:
- JSON for structured manifests
- JSONL/NDJSON for event streams
- PCAP for packet evidence
- text logs for tool output

## Reduction tools

Use:
- jq
- yq
- Miller
- ripgrep
- tshark
- Zeek
- Suricata

LLMs should generally receive reduced, relevant evidence rather than unbounded raw telemetry.

## Finding contract

```json
{
  "finding_id": "F001",
  "claim": "example",
  "evidence": ["network.json", "network.pcap"],
  "confidence": 0.97,
  "verified": false
}
```

## Evidence index

```json
{
  "artifact": "network.pcap",
  "type": "pcap",
  "sha256": "...",
  "source": "tcpdump",
  "timestamp": "...",
  "description": "packet capture during target command"
}
```
