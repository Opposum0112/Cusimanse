# Cusimanse Research Contracts

This directory contains the Markdown research contracts used by Cusimanse experiments. Contracts define intent, scope, hypotheses, safety constraints, evidence requirements, acceptance criteria, and review/promotion gates.

Each case contract should define:

- research question and hypothesis
- authorized scope and workload
- safety constraints and prohibited actions
- required compute/isolation boundary
- required VM-side instrumentation
- evidence and provenance requirements
- independent verification requirements
- human approval gates
- acceptance and cleanup criteria

Recipes in `recipes/` provide the executable configuration that implements the contract.
