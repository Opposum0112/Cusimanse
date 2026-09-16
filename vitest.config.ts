import { defineConfig } from "vitest/config";
export default defineConfig({ test: { include: ["vitest-tests/**/*.test.ts"], exclude: ["node_modules/**"] } });
