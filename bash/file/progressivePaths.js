/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import fs from "node:fs";
function label(item) {
  return item.parts.slice(-item.depth).join("/");
}
const lines = fs
  .readFileSync(0, "utf8")
  .split("\n")
  .map((l) => l.trim())
  .filter((l) => l.length > 0);
const items = [...new Set(lines)]
  .map((original) => ({ original, parts: original.split("/").filter((p) => p.length > 0), depth: 1 }))
  .filter((item) => item.parts.length > 0);
let changed = true;
while (changed) {
  changed = false;
  const count = /* @__PURE__ */ new Map();
  const ancestors = /* @__PURE__ */ new Set();
  for (const item of items) {
    const l = label(item);
    count.set(l, (count.get(l) || 0) + 1);
    const parts = l.split("/");
    for (let i = 1; i < parts.length; i++) {
      ancestors.add(parts.slice(0, i).join("/"));
    }
  }
  for (const item of items) {
    const l = label(item);
    const conflict = (count.get(l) || 0) > 1 || ancestors.has(l);
    if (conflict && item.depth < item.parts.length) {
      item.depth += 1;
      changed = true;
    }
  }
}
process.stdout.write(
  items
    .map(
      (item) => `${item.original}	${label(item)}
`
    )
    .join("")
);
