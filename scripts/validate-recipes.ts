import { readFile } from "node:fs/promises";
import { parse } from "yaml";
import { compileRecipe } from "../src/compiler/index.js";

const recipe = parse(await readFile("recipes/examples/npm-install.yaml", "utf8")) as unknown;
compileRecipe(recipe, { format: "yaml", path: "recipes/examples/npm-install.yaml" });
const schema = parse(await readFile("schema/cusimanse-agent-runtime.yaml", "utf8")) as unknown;
if (typeof schema !== "object" || schema === null) throw new Error("Recipe schema is not a YAML object.");
console.log("Recipe schema and example validation passed.");
