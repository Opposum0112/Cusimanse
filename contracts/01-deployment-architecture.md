# Goose-native architecture contract

## Purpose
Define the architecture of Cusimanse as a Goose-native research workflow. Goose is the primary operator; Goose recipes are the reusable executable configuration.

## Native architecture

```text
Research Contract
      ↓
Goose Recipe
      ↓
Goose Session
 ┌────┼───────────────┐
Plan Skills Summon/MCP
      ↓
Optional Container Use
      ↓
Workload + Evidence
      ↓
Specialist Subrecipes
      ↓
Verification
      ↓
Research Report
```

Goose recipes natively package prompts, instructions, parameters, extensions, settings and subrecipes. Summon provides delegation; Skills provide reusable instructions; Container Use provides an isolated development environment. These are the supported primitives used by this branch.

## Explicitly removed from the architecture

No external orchestration controller, custom model gateway, custom policy engine, custom session-state service, or alternate primary-agent adapter is required. Unsupported capabilities are not represented as part of the execution path.

## Boundary

Goose itself is not the security boundary. The researcher must select an appropriate isolated environment. For repository/workload isolation, Container Use is the Goose-native reference integration. Host permissions and extension permissions remain the responsibility of the researcher.

## Acceptance

The architecture is valid when every executable step can be represented by a Goose recipe, built-in/platform extension, configured MCP extension, Skill, subrecipe or ordinary workload command, and when the final report is backed by recorded files rather than model output alone.
