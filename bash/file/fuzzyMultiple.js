/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import fs from "node:fs";
import tty from "node:tty";
import readline from "node:readline";
function fuzzyMatch(line, token) {
  if (token.length === 0) {
    return { indices: [], score: 0 };
  }
  const lowerLine = line.toLowerCase();
  const lowerToken = token.toLowerCase();
  const subIdx = lowerLine.indexOf(lowerToken);
  if (subIdx !== -1) {
    const indices2 = [];
    for (let i = 0; i < lowerToken.length; i++) {
      indices2.push(subIdx + i);
    }
    const score = 1e3 + subIdx * 2;
    return { indices: indices2, score };
  }
  let tIdx = 0;
  const indices = [];
  for (let i = 0; i < line.length && tIdx < lowerToken.length; i++) {
    if (lowerLine[i] === lowerToken[tIdx]) {
      indices.push(i);
      tIdx++;
    }
  }
  if (tIdx === lowerToken.length) {
    let score = 0;
    let prev = -2;
    for (let k = 0; k < indices.length; k++) {
      const idx = indices[k];
      if (idx === prev + 1) {
        score += 25;
      }
      if (idx === 0 || "/_.-".includes(line[idx - 1])) {
        score += 20;
      }
      if (line[idx] === token[k]) {
        score += 5;
      }
      prev = idx;
    }
    const span = indices[indices.length - 1] - indices[0];
    score -= span;
    score -= line.length * 0.1;
    return { indices, score };
  } else {
    return null;
  }
}
function matchLine(line, query) {
  const trimmed = query.trim();
  if (trimmed.length === 0) {
    return { indices: [], score: 0 };
  }
  const tokens = trimmed.split(/\s+/).filter((t) => t.length > 0);
  const combinedIndices = [];
  let totalScore = 0;
  for (const token of tokens) {
    const match = fuzzyMatch(line, token);
    if (match === null) {
      return null;
    }
    combinedIndices.push(...match.indices);
    totalScore += match.score;
  }
  return { indices: combinedIndices, score: totalScore };
}
function formatHighlightedLine(line, indices, isCurrent, isSelected) {
  const REVERSE = "\x1B[7m";
  const RESET_REVERSE = "\x1B[27m";
  const RESET = "\x1B[0m";
  const GREEN = "\x1B[32m";
  const YELLOW = "\x1B[1;33m";
  const indexSet = new Set(indices);
  let highlighted = "";
  for (let i = 0; i < line.length; i++) {
    const char = line[i];
    if (indexSet.has(i)) {
      highlighted += `${REVERSE}${char}${RESET_REVERSE}`;
    } else {
      highlighted += char;
    }
  }
  const marker = isSelected ? `${GREEN}[x]${RESET}` : "[ ]";
  if (isCurrent) {
    return `${YELLOW}>${RESET} ${marker} ${YELLOW}${highlighted}${RESET}`;
  } else {
    return `  ${marker} ${highlighted}${RESET}`;
  }
}
async function readStdinLines() {
  const rl = readline.createInterface({
    input: process.stdin,
    crlfDelay: Infinity,
  });
  const lines = [];
  for await (const line of rl) {
    if (line.trim().length > 0) {
      lines.push(line.trim());
    }
  }
  return [...new Set(lines)];
}
async function main() {
  if (process.stdin.isTTY) {
    process.stderr.write("fuzzyMultiple.ts error: list of lines on stdin is required\n");
    process.exit(1);
  }
  const allLines = await readStdinLines();
  if (allLines.length === 0) {
    process.stderr.write("fuzzyMultiple.ts error: input stream is empty\n");
    process.exit(1);
  }
  let ttyInFd;
  let ttyOutFd;
  try {
    ttyInFd = fs.openSync("/dev/tty", "r");
    ttyOutFd = fs.openSync("/dev/tty", "w");
  } catch (err) {
    process.stderr.write(
      `fuzzyMultiple.ts error: cannot open /dev/tty (${err instanceof Error ? err.message : String(err)})
`
    );
    process.exit(1);
  }
  const ttyIn = new tty.ReadStream(ttyInFd);
  const ttyOut = new tty.WriteStream(ttyOutFd);
  let query = "";
  let cursorIndex = 0;
  let currentIndex = 0;
  let scrollOffset = 0;
  let renderedLineCount = 0;
  let filtered = [];
  const selected = /* @__PURE__ */ new Set();
  const preselectIndex = process.argv.indexOf("--preselect");
  if (preselectIndex !== -1) {
    const preselectFile = process.argv[preselectIndex + 1];
    if (!preselectFile) {
      process.stderr.write("fuzzyMultiple.ts error: --preselect requires path to a file\n");
      process.exit(1);
    }
    const known = new Set(allLines);
    for (const line of fs.readFileSync(preselectFile, "utf8").split("\n")) {
      if (known.has(line.trim())) {
        selected.add(line.trim());
      }
    }
  }
  function updateFiltered() {
    if (query.trim().length === 0) {
      filtered = allLines.map((line) => ({
        line,
        indices: [],
        score: 0,
      }));
    } else {
      const matches = [];
      for (const line of allLines) {
        const match = matchLine(line, query);
        if (match !== null) {
          matches.push({
            line,
            indices: match.indices,
            score: match.score,
          });
        }
      }
      matches.sort((a, b) => b.score - a.score);
      filtered = matches;
    }
  }
  function cleanupAndExit(selectedLines, exitCode) {
    let clearBuf = "";
    if (renderedLineCount > 0) {
      clearBuf += `\r\x1B[${renderedLineCount}A`;
      for (let i = 0; i < renderedLineCount; i++) {
        clearBuf += `\r\x1B[2K\r
`;
      }
      clearBuf += `\x1B[${renderedLineCount}A\r`;
    }
    clearBuf += "\x1B[?7h\x1B[?25h";
    ttyOut.write(clearBuf);
    try {
      ttyIn.setRawMode(false);
      ttyIn.pause();
      fs.closeSync(ttyInFd);
      fs.closeSync(ttyOutFd);
    } catch {}
    if (selectedLines !== null && selectedLines.length > 0 && exitCode === 0) {
      process.stdout.write(selectedLines.join("\n") + "\n", () => {
        process.exit(0);
      });
    } else {
      process.stderr.write("fuzzyMultiple.ts error: nothing selected\n");
      process.exit(1);
    }
  }
  function render() {
    const terminalHeight = ttyOut.rows || 24;
    const maxVisible = Math.max(3, Math.min(15, terminalHeight - 4));
    if (filtered.length === 0) {
      currentIndex = 0;
    } else if (currentIndex >= filtered.length) {
      currentIndex = filtered.length - 1;
    } else if (currentIndex < 0) {
      currentIndex = 0;
    }
    if (cursorIndex < 0) {
      cursorIndex = 0;
    } else if (cursorIndex > query.length) {
      cursorIndex = query.length;
    }
    if (currentIndex < scrollOffset) {
      scrollOffset = currentIndex;
    } else if (currentIndex >= scrollOffset + maxVisible) {
      scrollOffset = currentIndex - maxVisible + 1;
    }
    const visibleItems = filtered.slice(scrollOffset, scrollOffset + maxVisible);
    const linesToRender = [];
    const countStr = ` (${filtered.length}/${allLines.length}, selected: ${selected.size}/${allLines.length})`;
    let queryWithCursor = "";
    if (cursorIndex < query.length) {
      const before = query.slice(0, cursorIndex);
      const at = query[cursorIndex];
      const after = query.slice(cursorIndex + 1);
      queryWithCursor = `${before}\x1B[7m${at}\x1B[27m${after}`;
    } else {
      queryWithCursor = `${query}\x1B[7m \x1B[27m`;
    }
    linesToRender.push(`> ${queryWithCursor}\x1B[90m${countStr}\x1B[0m`);
    linesToRender.push(
      "\x1B[90m  Tab: toggle | Ctrl+A: all | Ctrl+X: none | Ctrl+T: invert | Enter: confirm | Esc: cancel\x1B[0m"
    );
    for (let i = 0; i < visibleItems.length; i++) {
      const itemIndex = scrollOffset + i;
      const match = visibleItems[i];
      linesToRender.push(
        formatHighlightedLine(match.line, match.indices, itemIndex === currentIndex, selected.has(match.line))
      );
    }
    if (visibleItems.length === 0) {
      linesToRender.push("  \x1B[90m(no matches)\x1B[0m");
    }
    let buf = "\x1B[?7l\x1B[?25l";
    if (renderedLineCount > 0) {
      buf += `\r\x1B[${renderedLineCount}A`;
    }
    for (let i = 0; i < linesToRender.length; i++) {
      buf += `\r\x1B[2K${linesToRender[i]}\r
`;
    }
    if (renderedLineCount > linesToRender.length) {
      const diff = renderedLineCount - linesToRender.length;
      for (let i = 0; i < diff; i++) {
        buf += "\r\x1B[2K\r\n";
      }
      buf += `\x1B[${diff}A`;
    }
    renderedLineCount = linesToRender.length;
    ttyOut.write(buf);
  }
  process.on("SIGINT", () => cleanupAndExit(null, 1));
  process.on("SIGTERM", () => cleanupAndExit(null, 1));
  ttyIn.setRawMode(true);
  ttyIn.resume();
  ttyIn.setEncoding("utf8");
  updateFiltered();
  render();
  ttyIn.on("data", (chunk) => {
    if (chunk === "") {
      cleanupAndExit(null, 1);
      return;
    }
    if (chunk === "") {
      cleanupAndExit(null, 1);
      return;
    }
    if (chunk === "\r" || chunk === "\n") {
      if (selected.size > 0) {
        cleanupAndExit(
          allLines.filter((line) => selected.has(line)),
          0
        );
      } else if (filtered.length > 0) {
        cleanupAndExit([filtered[currentIndex].line], 0);
      } else {
        cleanupAndExit(null, 1);
      }
      return;
    }
    if (chunk === "	") {
      if (filtered.length > 0) {
        const line = filtered[currentIndex].line;
        if (selected.has(line)) {
          selected.delete(line);
        } else {
          selected.add(line);
        }
        currentIndex = Math.min(filtered.length - 1, currentIndex + 1);
        render();
      }
      return;
    }
    if (chunk === "") {
      for (const match of filtered) {
        selected.add(match.line);
      }
      render();
      return;
    }
    if (chunk === "") {
      for (const match of filtered) {
        selected.delete(match.line);
      }
      render();
      return;
    }
    if (chunk === "") {
      for (const match of filtered) {
        if (selected.has(match.line)) {
          selected.delete(match.line);
        } else {
          selected.add(match.line);
        }
      }
      render();
      return;
    }
    if (chunk === "\x7F" || chunk === "\b") {
      if (cursorIndex > 0) {
        query = query.slice(0, cursorIndex - 1) + query.slice(cursorIndex);
        cursorIndex -= 1;
        currentIndex = 0;
        updateFiltered();
        render();
      }
      return;
    }
    if (chunk === "\x1B[3~") {
      if (cursorIndex < query.length) {
        query = query.slice(0, cursorIndex) + query.slice(cursorIndex + 1);
        currentIndex = 0;
        updateFiltered();
        render();
      }
      return;
    }
    if (chunk === "\x1B[D" || chunk === "\x1BOD") {
      if (cursorIndex > 0) {
        cursorIndex -= 1;
        render();
      }
      return;
    }
    if (chunk === "\x1B[C" || chunk === "\x1BOC") {
      if (cursorIndex < query.length) {
        cursorIndex += 1;
        render();
      }
      return;
    }
    if (chunk === "\x1B[H" || chunk === "\x1B[1~" || chunk === "\x1B[7~" || chunk === "\x1BOH") {
      cursorIndex = 0;
      render();
      return;
    }
    if (chunk === "\x1B[F" || chunk === "\x1B[4~" || chunk === "\x1B[8~" || chunk === "\x1BOF" || chunk === "") {
      cursorIndex = query.length;
      render();
      return;
    }
    if (chunk === "\x1B[A" || chunk === "\x1BOA" || chunk === "") {
      if (filtered.length > 0) {
        currentIndex = (currentIndex - 1 + filtered.length) % filtered.length;
        render();
      }
      return;
    }
    if (chunk === "\x1B[B" || chunk === "\x1BOB" || chunk === "") {
      if (filtered.length > 0) {
        currentIndex = (currentIndex + 1) % filtered.length;
        render();
      }
      return;
    }
    if (chunk === "\x1B[5~") {
      if (filtered.length > 0) {
        currentIndex = Math.max(0, currentIndex - 5);
        render();
      }
      return;
    }
    if (chunk === "\x1B[6~") {
      if (filtered.length > 0) {
        currentIndex = Math.min(filtered.length - 1, currentIndex + 5);
        render();
      }
      return;
    }
    if (chunk === "\x1B") {
      cleanupAndExit(null, 1);
      return;
    }
    if (chunk === "") {
      query = "";
      cursorIndex = 0;
      currentIndex = 0;
      updateFiltered();
      render();
      return;
    }
    if (chunk === "") {
      if (cursorIndex > 0) {
        const before = query.slice(0, cursorIndex);
        const after = query.slice(cursorIndex);
        const trimmed = before.trimEnd();
        const lastSpace = trimmed.lastIndexOf(" ");
        const newBefore = lastSpace >= 0 ? trimmed.slice(0, lastSpace + 1) : "";
        cursorIndex = newBefore.length;
        query = newBefore + after;
        currentIndex = 0;
        updateFiltered();
        render();
      }
      return;
    }
    if (chunk.startsWith("\x1B")) {
      return;
    }
    if (chunk.charCodeAt(0) >= 32 && chunk.charCodeAt(0) !== 127) {
      query = query.slice(0, cursorIndex) + chunk + query.slice(cursorIndex);
      cursorIndex += chunk.length;
      currentIndex = 0;
      updateFiltered();
      render();
    }
  });
}
try {
  await main();
} catch (err) {
  process.stderr.write(`fuzzyMultiple.ts error: ${err instanceof Error ? err.message : String(err)}
`);
  process.exit(1);
}
