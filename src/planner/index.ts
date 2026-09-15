import type { CapabilityIntent, CusimanseIR, DependencyGraph } from "../ir/index.js";

export interface CompiledPlan {
  graph: DependencyGraph;
  orderedIntentIds: string[];
}

export class PlannerError extends Error {
  constructor(message: string, readonly issues: string[] = []) {
    super(message);
    this.name = "PlannerError";
  }
}

export function buildDependencyGraph(ir: CusimanseIR): DependencyGraph {
  const issues: string[] = [];
  const ids = new Set<string>();

  for (const intent of ir.intents) {
    if (ids.has(intent.id)) issues.push(`duplicate intent id: ${intent.id}`);
    ids.add(intent.id);
  }

  const dependencies: Record<string, string[]> = {};
  for (const intent of ir.intents) {
    const uniqueDependencies = [...new Set(intent.dependsOn)];
    dependencies[intent.id] = uniqueDependencies;
    for (const dependency of uniqueDependencies) {
      if (!ids.has(dependency)) issues.push(`intent ${intent.id} depends on missing intent: ${dependency}`);
      if (dependency === intent.id) issues.push(`intent ${intent.id} cannot depend on itself`);
    }
  }

  if (issues.length) throw new PlannerError("Invalid dependency graph.", issues);

  return {
    nodes: ir.intents.map((intent) => intent.id),
    dependencies,
  };
}

export function planExecution(ir: CusimanseIR): CompiledPlan {
  const graph = buildDependencyGraph(ir);
  const remaining = new Set(graph.nodes);
  const orderedIntentIds: string[] = [];

  while (remaining.size > 0) {
    const ready = [...remaining]
      .filter((id) => graph.dependencies[id]?.every((dependency) => orderedIntentIds.includes(dependency)))
      .sort();

    if (ready.length === 0) {
      const cycle = [...remaining].sort();
      throw new PlannerError(`Dependency cycle detected: ${cycle.join(", ")}`, [
        `unresolved intents: ${cycle.join(", ")}`,
      ]);
    }

    for (const id of ready) {
      orderedIntentIds.push(id);
      remaining.delete(id);
    }
  }

  return { graph, orderedIntentIds };
}

export function getReadyIntents(
  ir: CusimanseIR,
  completedIntentIds: ReadonlySet<string>,
): CapabilityIntent[] {
  const graph = buildDependencyGraph(ir);
  return ir.intents.filter(
    (intent) =>
      !completedIntentIds.has(intent.id) &&
      graph.dependencies[intent.id]?.every((dependency) => completedIntentIds.has(dependency)),
  );
}
