import { InMemoryRuntime } from "./local-driver.js";
import { TemporalDurableRuntime } from "./temporal-driver.js";
import { LangGraphRuntime } from "./graph-driver.js";
import type { ExperimentRuntime } from "./spi/types.js";
export function getExperimentRuntime(runtimeId: string): ExperimentRuntime { if (runtimeId === "local") return new InMemoryRuntime(); if (runtimeId === "temporal") return new TemporalDurableRuntime(); if (runtimeId === "graph") return new LangGraphRuntime(); throw new Error(`Unknown execution runtime: ${runtimeId}`); }
