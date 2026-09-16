import { spawn } from "node:child_process";
import type { ExecResult } from "./types.js";

export function runProcess(command: string, args: string[], cwd?: string): Promise<ExecResult> {
  const started = Date.now();
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, { cwd, stdio: ["ignore", "pipe", "pipe"] });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (chunk: Buffer) => { stdout += chunk.toString(); });
    child.stderr.on("data", (chunk: Buffer) => { stderr += chunk.toString(); });
    child.on("error", reject);
    child.on("close", (exitCode) => resolve({ exitCode: exitCode ?? 1, stdout, stderr, durationMs: Date.now() - started }));
  });
}
