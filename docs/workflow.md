# Disposable research workflow

`DisposableResearchWorkflow` composes CAR runtime orchestration with `LimaLifecycle`.

1. Create the declared disposable compute profile.
2. Run the validated IR through planning, capability resolution, policy/approval, operation execution, observation, and optional reasoning.
3. Preserve evidence through the injected evidence collector/adapters.
4. Destroy the declared VM in a `finally` block, including when runtime execution fails.

The workflow owns lifecycle sequencing but does not construct arbitrary host commands. A concrete `LimaProvider` remains an injected boundary.
