# Vercel AI SDK 7 reasoning layer

CAR uses Vercel AI SDK structured output through `generateText` and `Output.object`. The model returns a typed proposal only. No CAR adapter is exposed as an AI SDK tool.

The proposal must enter CAR's normal validation, planning, capability-resolution, policy, approval, and operation path before any side effect can occur.

The integration targets the AI SDK 7 structured-output API: `Output.object({ schema })` supplies a schema-validated structured result to `generateText`.
