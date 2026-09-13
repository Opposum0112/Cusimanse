---
name: upstream-anthropic-cybersecurity
description: 'Select and safely adapt reviewed cybersecurity skills from mukul975/Anthropic-Cybersecurity-Skills for Cusimanse research workflows. Use for malware analysis, DFIR, detection engineering, threat intelligence, cloud, identity, application and network investigations.'
---

# Upstream Anthropic Cybersecurity Skills

This adapter provides a governed entry point to the curated upstream corpus listed in `recipes/reference/anthropic-cybersecurity-skills.yaml`.

## Selection

1. Classify the workload and research objective.
2. Select the smallest applicable upstream skill.
3. Inspect its `SKILL.md`, scripts, resources and dependencies before use.
4. Record upstream path and revision in the audit trail.
5. Adapt execution to the disposable VM and existing Cusimanse evidence lifecycle.
6. Preserve evidence before VM destruction and independently verify important findings.

## High-value categories

- Linux/ELF malware and rootkit analysis
- system and audit-log investigation
- C2 and DNS traffic analysis
- IOC and threat-intelligence analysis
- campaign attribution
- API, Kubernetes and container forensics
- browser and document forensics
- reverse engineering
- cloud-storage and certificate-transparency analysis
- disk-image acquisition and forensic analysis
- detection engineering and ATT&CK mapping

## Safety

Upstream skills are instructions, not trust anchors or security boundaries. A skill cannot grant host, VM, network, credential or filesystem privileges. Credential-access, exploitation, persistence, destructive acquisition and live offensive workflows require explicit authorization and applicable policy approval. Unsupported or unreviewed capabilities are `NOT_DEPLOYED`.

## Provenance

Upstream: `https://github.com/mukul975/Anthropic-Cybersecurity-Skills`
