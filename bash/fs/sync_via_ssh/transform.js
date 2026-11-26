/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import { createInterface } from "node:readline";
import { lstat } from "node:fs/promises";
import path from "node:path";
const input = createInterface({
  input: process.stdin,
  crlfDelay: Infinity,
});
async function exists(file) {
  try {
    await lstat(file);
    return true;
  } catch (error) {
    if (error.code === "ENOENT") {
      return false;
    }
    throw error;
  }
}
for await (const line of input) {
  const match = /^(.*?)\s+([A-Za-z][A-Za-z,]*)$/.exec(line);
  if (!match) {
    console.error(`Unrecognized fswatch output: ${line}`);
    continue;
  }
  const [, rawPath, rawFlags] = match;
  const file = path.resolve(rawPath);
  const flags = new Set(rawFlags.split(","));
  try {
    let action;
    if (!(await exists(file))) {
      action = "deleted";
    } else if (flags.has("Created")) {
      action = "create";
    } else {
      action = "update";
    }
    const relativePath = path.relative(process.cwd(), file);
    console.log(`${action} ${relativePath}`);
  } catch (error) {
    console.error(`Failed to inspect ${rawPath}:`, error);
  }
}
