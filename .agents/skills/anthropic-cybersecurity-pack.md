---
name: anthropic-cybersecurity-pack
description: Curated, repository-adapted index of security research skills sourced from mukul975/Anthropic-Cybersecurity-Skills. Use for Linux malware triage, DNS threat detection, forensic analysis, IOC analysis, detection engineering, cloud investigation, reverse engineering and incident analysis. Do not use this index as authorization to attack external systems.
domain: cybersecurity
source: https://github.com/mukul975/Anthropic-Cybersecurity-Skills
source_license: Apache-2.0
---

# Curated Anthropic Cybersecurity Skill Pack

The upstream project publishes a large Agent Skills-compatible cybersecurity library. Cusimanse does **not** blindly import the entire collection: some skills contain offensive or dual-use procedures. This pack selects skills that fit controlled research, defensive analysis, evidence handling and detection workflows.

## Recommended skills

### Malware and binary analysis
- `analyzing-linux-elf-malware` — Linux ELF static/dynamic analysis and reverse engineering.
- `analyzing-golang-malware-with-ghidra` — Go malware binary analysis.
- `analyzing-bootkit-and-rootkit-samples` — boot/firmware/rootkit investigation.
- `analyzing-linux-kernel-rootkits` — Linux kernel-rootkit detection.
- `analyzing-command-and-control-communication` — captured C2 traffic analysis.
- `analyzing-cobalt-strike-beacon-configuration` — Beacon configuration extraction from authorized samples.

### Network and detection analysis
- `analyzing-dns-logs-for-exfiltration` — DNS tunneling/DGA anomaly detection.
- `analyzing-api-gateway-access-logs` — API abuse and anomaly analysis.
- `analyzing-network-traffic-of-malware` — malware network behavior analysis.
- `analyzing-indicators-of-compromise` — IOC normalization and enrichment.
- `analyzing-kubernetes-audit-logs` — Kubernetes audit investigation.
- `analyzing-linux-audit-logs-for-intrusion` — Linux auditd investigation.

### Forensics
- `acquiring-disk-image-with-dd-and-dcfldd` — controlled forensic acquisition and hashing.
- `analyzing-disk-image-with-autopsy` — disk-image investigation.
- `analyzing-browser-forensics-with-hindsight` — browser artifact analysis.
- `analyzing-linux-system-artifacts` — Linux persistence and activity artifacts.
- `analyzing-lnk-file-and-jump-list-artifacts` — Windows user-activity artifacts.

### Threat intelligence and attribution
- `analyzing-apt-group-with-mitre-navigator` — ATT&CK-based threat-actor mapping.
- `analyzing-campaign-attribution-evidence` — evidence-weighted attribution.
- `analyzing-certificate-transparency-for-phishing` — CT-based phishing discovery.

### Application and cloud security
- `analyzing-azure-activity-logs-for-threats` — Azure activity/sign-in investigation.
- `analyzing-cloud-storage-access-patterns` — cloud-storage anomaly analysis.
- `analyzing-ethereum-smart-contract-vulnerabilities` — authorized smart-contract analysis.
- `analyzing-docker-container-forensics` — container evidence investigation.

### Document and mobile analysis
- `analyzing-android-malware-with-apktool` — APK static malware analysis.
- `analyzing-ios-app-security-with-objection` — authorized iOS runtime security analysis.
- `analyzing-macro-malware-in-office-documents` — malicious-document analysis.
- `analyzing-malicious-pdf-with-peepdf` — PDF static analysis.
- `analyzing-email-headers-for-phishing-investigation` — phishing-header analysis.

## Cusimanse adaptation rules

1. Import source skills only after inspecting `SKILL.md`, scripts and referenced resources.
2. Preserve provenance, source commit/release and license information.
3. Treat skills as instructions, never as a security boundary.
4. Execute workload actions only inside the approved disposable VM boundary.
5. Offensive/dual-use procedures require explicit authorized-research scope and appropriate approval.
6. Public enrichment must not receive private workload data.
7. Preserve and hash evidence before VM destruction.
8. Findings require independent verification.
9. Unsupported tools or missing capabilities are `NOT_DEPLOYED`.
10. Do not automatically install or execute every upstream skill.

## Upstream reference

The upstream library reports hundreds of Agent Skills-compatible cybersecurity skills across malware analysis, detection, forensics, cloud, threat intelligence and other domains. Cusimanse maintains this curated layer so the security boundary remains explicit while the larger upstream catalog remains available for controlled review.
