import { access, mkdir, readdir, rename } from "node:fs/promises";
import { basename, join, relative, resolve } from "node:path";
import { readFile } from "node:fs/promises";

export interface SkillSpec { id: string; version: string; capability: string; description?: string; }
const candidateRoot = resolve("skills/candidate");
const validatedRoot = resolve("skills/validated");

export async function proposeSkill(spec: SkillSpec): Promise<string> { return join(candidateRoot, spec.id); }
export async function validateSkill(candidatePath: string): Promise<SkillSpec> {
  const source = safeCandidate(candidatePath);
  await access(join(source, "SKILL.md")); await access(join(source, "schema.json"));
  const schema: unknown = JSON.parse(await readFile(join(source, "schema.json"), "utf8"));
  if (!isRecord(schema) || typeof schema.type !== "string") throw new Error("schema.json must contain a JSON Schema type.");
  const markdown = await readFile(join(source, "SKILL.md"), "utf8");
  const metadata = parseMetadata(markdown);
  const id = metadata.id ?? basename(source); const version = metadata.version ?? "1.0.0"; const capability = metadata.capability ?? id;
  if (!/^[a-z0-9][a-z0-9._-]*$/u.test(id)) throw new Error("Skill id contains unsafe characters.");
  return { id, version, capability, ...(metadata.description ? { description: metadata.description } : {}) };
}
export async function promoteSkill(candidatePath: string): Promise<{ id: string; path: string }> {
  const spec = await validateSkill(candidatePath);
  const source = safeCandidate(candidatePath); const destination = join(validatedRoot, spec.id);
  await mkdir(validatedRoot, { recursive: true });
  try { await access(destination); throw new Error(`Validated skill already exists: ${spec.id}`); } catch (error) { if (!(error instanceof Error) || !error.message.startsWith("ENOENT")) throw error; }
  await rename(source, destination);
  return { id: spec.id, path: destination };
}
export async function listValidatedSkills(): Promise<string[]> { try { return (await readdir(validatedRoot)).filter((name) => !name.startsWith(".")).sort(); } catch { return []; } }
function safeCandidate(input: string): string { const source = resolve(input); const rel = relative(candidateRoot, source); if (!rel || rel.startsWith("..") || rel.includes(".." + "/")) throw new Error("Candidate must live under skills/candidate."); return source; }
function parseMetadata(markdown: string): Record<string, string> { const result: Record<string, string> = {}; for (const line of markdown.split(/\r?\n/u).slice(0, 30)) { const match = line.match(/^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.+)$/u); if (match) { const key = match[1]; const value = match[2]; if (key && value) result[key] = value.trim().replace(/^['"]|['"]$/gu, ""); } } return result; }
function isRecord(value: unknown): value is Record<string, unknown> { return typeof value === "object" && value !== null && !Array.isArray(value); }
