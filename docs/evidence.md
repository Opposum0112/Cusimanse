# Evidence and provenance

`EvidenceCollector` records evidence identity and provenance without executing or uploading artifacts. Each record contains evidence kind, URI, SHA-256, byte size, experiment ID, optional operation ID, and recording time.

Adapters can use the returned evidence reference in their `evidenceRefs` result. The runtime keeps execution authority separate from evidence identity and preservation.
