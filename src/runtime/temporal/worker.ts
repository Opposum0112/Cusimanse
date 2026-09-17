import { NativeConnection, Worker } from "@temporalio/worker";
import * as activities from "./activities.js";

const address = process.env.TEMPORAL_ADDRESS ?? "localhost:7233";
const namespace = process.env.TEMPORAL_NAMESPACE ?? "default";
const taskQueue = process.env.CUSIMANSE_TEMPORAL_TASK_QUEUE ?? "cusimanse-research";

const connection = await NativeConnection.connect({ address });
const worker = await Worker.create({
  connection,
  namespace,
  taskQueue,
  workflowsPath: new URL("./workflow.js", import.meta.url).pathname,
  activities,
});

console.log(`Cusimanse Temporal worker listening on ${address}, queue=${taskQueue}`);
await worker.run();
