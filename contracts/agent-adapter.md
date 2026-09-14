# Agent adapter contract

## Purpose

Cusimanse experiments are agent-neutral at the recipe layer. Goose is the reference primary operator because it natively supports recipes, reusable agents/subagents, Skills and MCP-based extensions. Other agents may drive the same experiment through an adapter and prompt handoff.

## Invariants

An adapter must preserve the contract, experiment recipe, session-state contract, Lima/QEMU execution boundary, instrumentation profile, evidence structure, independent verification and report structure.

The adapter is not a security boundary and must not expand experiment scope, bypass policy, or replace the VM/guest-OS containment boundary.

## Goose role orchestration

Role definitions remain in `.agents/agents/`. Goose uses native delegation to load the appropriate role definition and may execute independent analysis roles in parallel. Lifecycle-critical steps remain ordered: plan → approval → provision → instrument → workload → evidence → verify → report → preserve → destroy.

The experiment recipe can declare `sub_recipes`; Goose's Summon extension provides recipe/agent/subrecipe delegation. Goose Skills supplies reusable procedural knowledge, while MCP extensions supply scoped tools/resources. These are capability layers, not evidence or containment boundaries.

## Other agents

OpenCode, Hermes, Antigravity and Pi receive the same contract, experiment recipe and prompt reference. Their native plugins/extensions/skills/MCP capabilities may be used when compatible. A missing native capability is recorded as PARTIAL/unsupported rather than silently replacing the experiment.

## Runtime acceptance

CLI availability alone is not integration success. A validated adapter must produce a session state, evidence index, independent verification and researcher report for a reference experiment.
