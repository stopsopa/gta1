/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import { createInterface } from "node:readline";
import { spawn } from "node:child_process";
import { lstat } from "node:fs/promises";
import path from "node:path";
const root = process.cwd();
const sshUser = process.env.SSH_USER;
const sshHost = process.env.SSH_HOST;
const sshDir = process.env.SSH_DIR;
if (!sshUser || !sshHost || !sshDir) {
  console.error("Required env vars: SSH_USER, SSH_HOST, SSH_DIR");
  process.exit(1);
}
const remoteDir = sshDir.endsWith("/") ? sshDir : `${sshDir}/`;
const destination = `${sshUser}@${sshHost}:${remoteDir}`;
const debounceMs = 300;
const pending = /* @__PURE__ */ new Set();
let timer;
let running = false;
function schedule(file) {
  const absolute = path.resolve(root, file);
  if (absolute !== root && !absolute.startsWith(root + path.sep)) {
    console.error(`Ignoring path outside project: ${file}`);
    return;
  }
  pending.add(path.relative(root, absolute));
  clearTimeout(timer);
  timer = setTimeout(() => void sync(), debounceMs);
}
function run(command, args) {
  return new Promise((resolve) => {
    const child = spawn(command, args, {
      cwd: root,
      stdio: "inherit",
    });
    child.on("error", (error) => {
      console.error(`${command} failed:`, error.message);
      resolve(1);
    });
    child.on("close", (code) => resolve(code ?? 1));
  });
}
async function sync() {
  if (running || pending.size === 0) return;
  running = true;
  const files = [...pending];
  pending.clear();
  const existing = [];
  const deleted = [];
  for (const file of files) {
    try {
      await lstat(path.resolve(root, file));
      existing.push(file);
    } catch {
      deleted.push(file);
    }
  }
  let failed = false;
  if (existing.length > 0) {
    const args = ["-az", "--relative", "--", ...existing.map((file) => `./${file}`), destination];
    if ((await run("rsync", args)) !== 0) {
      failed = true;
    }
  }
  for (const file of deleted) {
    const remotePath = `${remoteDir}${file}`;
    const status = await run("ssh", [`${sshUser}@${sshHost}`, "rm", "-f", "--", remotePath]);
    if (status !== 0) failed = true;
  }
  running = false;
  if (failed) {
    console.error("Sync failed. Change a file to retry.");
  }
  if (pending.size > 0) {
    void sync();
  }
}
const input = createInterface({
  input: process.stdin,
  crlfDelay: Infinity,
});
function getTimestamp() {
  const now = /* @__PURE__ */ new Date();
  const pad = (n) => String(n).padStart(2, "0");
  const YYYY = now.getFullYear();
  const MM = pad(now.getMonth() + 1);
  const DD = pad(now.getDate());
  const HH = pad(now.getHours());
  const mm = pad(now.getMinutes());
  const ss = pad(now.getSeconds());
  return `[${YYYY}-${MM}-${DD} ${HH}:${mm}:${ss}]`;
}
input.on("line", (line) => {
  console.log(`\x1B[32m${getTimestamp()} ${line}\x1B[0m`);
  const match = /^(?:create|update|deleted)\s+(.+)$/.exec(line);
  if (match) {
    schedule(match[1]);
  }
});
input.on("close", () => {
  clearTimeout(timer);
  if (pending.size > 0) void sync();
});
