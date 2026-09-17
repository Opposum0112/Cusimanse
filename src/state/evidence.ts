export interface EvidenceRecord {
  id: string;
  objectiveId: string;
  runId: string;
  traceId: string;
  tool: string;
  kind: "observation" | "artifact" | "verification";
  data: Record<string, unknown>;
  timestamp: string;
}

export class EvidenceJournal {
  private readonly records = new Map<string, EvidenceRecord>();

  append(record: EvidenceRecord): EvidenceRecord {
    if (!record.id.trim()) throw new Error("evidence.id is required");
    if (this.records.has(record.id)) throw new Error(`Evidence already exists: ${record.id}`);
    this.records.set(record.id, Object.freeze({ ...record, data: { ...record.data } }));
    return this.records.get(record.id)!;
  }

  get(id: string): EvidenceRecord | undefined { return this.records.get(id); }
  list(): EvidenceRecord[] { return [...this.records.values()]; }
}

export function createEvidenceId(runId: string, tool: string, sequence: number): string {
  if (!Number.isSafeInteger(sequence) || sequence < 0) throw new Error("evidence sequence must be a non-negative safe integer");
  return `evidence:${runId}:${sequence}:${tool}`;
}
