export interface CommandResult { stdout: string; stderr: string; exitCode: number; }

export interface ShellAdapter { execute(command: string, args: string[]): Promise<CommandResult>; }
export interface FileAdapter { read(path: string): Promise<string>; write(path: string, content: string): Promise<void>; }
export interface ProcessAdapter { list(): Promise<unknown>; }
export interface NpmAdapter { install(workingDirectory: string, args?: string[]): Promise<CommandResult>; }

export class WorkloadAdapters {
  constructor(
    readonly shell: ShellAdapter,
    readonly file: FileAdapter,
    readonly process: ProcessAdapter,
    readonly npm: NpmAdapter,
  ) {}
}
