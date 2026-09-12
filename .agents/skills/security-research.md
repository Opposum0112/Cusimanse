# Security Research Skills

These skills are reviewed research instructions. They do not grant privileges, bypass approvals, or define the VM security boundary.

## Core research skills

| Skill | Purpose | Primary evidence |
|---|---|---|
| experiment-planning | turn a research contract into bounded hypotheses and acceptance criteria | plan + contract |
| workload-triage | identify workload type, entry points and initial indicators | hashes + metadata |
| static-analysis | inspect binaries, packages, scripts and configuration without execution | extracted artifacts |
| dynamic-analysis | interpret process, filesystem, syscall and network behavior | runtime telemetry |
| network-analysis | analyze DNS, sockets, flows, protocols and captures | PCAP + flow records |
| malware-analysis | characterize suspicious behavior and persistence | VM evidence |
| reverse-engineering | reason about executable structure and behavior | disassembly/decompilation artifacts |
| threat-intelligence | enrich indicators and behaviors from approved references | source citations |
| vulnerability-research | map observed behavior to vulnerability hypotheses and affected components | reproducible evidence |
| dependency-analysis | inspect dependency provenance, versions and suspicious install/build behavior | lockfiles + SBOM |
| detection-engineering | convert verified behavior into YARA/Sigma/Suricata-style detections | tested rule + evidence |
| forensics | preserve, normalize and correlate filesystem/process artifacts | hashes + timeline |
| ioc-extraction | extract and normalize hashes, domains, URLs, IPs, paths and other indicators | IOC manifest |
| attack-mapping | map verified behavior to MITRE ATT&CK techniques | technique mapping + evidence |
| evidence-reduction | deterministically reduce large telemetry while retaining originals | reduction manifest |
| independent-verification | challenge important findings using a second method or source | verification record |
| research-reporting | produce reproducible findings with provenance and limitations | signed/hashed report |
| project-audit | audit material agent, MCP, skill, tool, policy and approval actions | audit record |

## Operating rules

1. Select skills from the registry; unknown skills are `NOT_DEPLOYED`.
2. Skills are instructions, not privileges.
3. Skills cannot grant host access, credentials, network reachability or VM control.
4. Material skill selection and execution is audited.
5. Evidence must precede claims of `PASS`.
6. External enrichment is reference material until independently corroborated.
7. Secrets and credentials must never be supplied as skill arguments.
8. Destructive, privileged and external-write operations require explicit policy/approval controls.
9. Prefer deterministic tooling before LLM interpretation.
10. Preserve original artifacts before reduction or VM destruction.
