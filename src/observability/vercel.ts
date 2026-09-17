import { OpenTelemetry } from "@ai-sdk/otel";
import { registerTelemetry } from "ai";

let registered = false;

/**
 * Register AI SDK 7's OpenTelemetry integration once at process startup.
 * Inputs and outputs remain disabled by default to avoid capturing sensitive
 * research prompts, tool payloads, or evidence content in telemetry.
 */
export function registerVercelTelemetry(): void {
  if (registered) return;
  registerTelemetry(new OpenTelemetry());
  registered = true;
}

export function isVercelTelemetryRegistered(): boolean {
  return registered;
}
