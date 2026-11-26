/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import fs from "node:fs";
import dotenv from "dotenv";
function fail(msg) {
  console.error(`${import.meta.filename} error: ${msg}`);
  process.exit(1);
}
const file = process.argv[2];
const override = process.argv[3] || "false";
if (typeof file !== "string" || !file.trim()) {
  fail(`.env file not specified - provide it in first arg`);
}
if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
  fail(`file '${file}' doesn't exist`);
}
if (override !== "true" && override !== "false") {
  fail(`second arg (override mode) should be 'true', 'false' or not specified, it is '${override}'`);
}
const parsed = dotenv.parse(fs.readFileSync(file));
for (const [key, value] of Object.entries(parsed)) {
  if (!/^[a-zA-Z_][a-zA-Z0-9_]*$/.test(key)) {
    console.error(`${import.meta.filename} warning: '${key}' is not valid name of shell variable - skipped`);
    continue;
  }
  if (override === "false" && typeof process.env[key] === "string") {
    continue;
  }
  console.log(`export ${key}='${value.replaceAll("'", `'\\''`)}'`);
}
