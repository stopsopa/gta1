/**
 * =================
 * Transpiled with transpile.ts, see transpile.ignore
 * =================
 */
import fs from "node:fs";
import path from "node:path";
import os from "node:os";
import process from "node:process";
import { fileURLToPath } from "node:url";
class HardlinkError extends Error {}
function fail(msg) {
  throw new HardlinkError(msg);
}
function showHelp() {
  const helpText = `
Usage:
  node bash/hardlink.ts <path/to/config.md> [options]

Options:
  --pwd                     Resolve paths relative to current working directory (process.cwd())
  --pwd <path>              Resolve paths relative to explicit <path> (also --pwd=<path>)
  --gitignore <path>        Path to .gitignore to ensure target file B paths are ignored (also --gitignore=<path>)
  --unlink                  Unlink existing hardlinked pairs (cannot be used with --gitignore)
                            (directory pairs are skipped)
  --absolute-symlink-dir    Directory pairs: create symlinks with absolute target path
                            (default: target relative to the directory of symlink B)
  --help, -h                Show this help page

  Unknown options and more than one config file are errors.

Gitignore delimiters:
  If the target gitignore contains the block delimiters:
    # hardlink.ts vvv
    # hardlink.ts ^^^
  new file B entries (relative to gitignore) are inserted inside this block (if not already present).
  If either delimiter is missing, entries are appended to the end of the file.
  Entry without "/" inside gets leading "/" (otherwise gitignore would match it on every level).
  Path B outside of the directory of gitignore is an error.

Config file format:
  The config file defines pairs of paths separated by " -> " (one pair per line).
  Empty lines are allowed.
  Paths can be in plain text or markdown link format [label](path).
  Quotes can be used for paths with spaces.
  Tilde (~) expands to the current user's home directory.

Examples of valid pairs in config.md:
  [one](./lib/test.ts) -> [two](./bin/test.ts)
  [one](./node_modules/some_lib/test.ts) -> [two](somewhere else/test.ts)
  path/to/file.log -> [two](./bin/path/to/file2.log)
  [one](./test/ttt.sh) -> ./test/ttt2.sh
  "path/with/ spaces /file log.log" -> [two](./bin/path/with/ spaces /file log2.log)
  ~/.test/ttt.sh -> [in home user](./test/ttt2.sh)

Directory pairs:
  When path A ends with "/" the pair links directories. Directory hardlinks are not possible,
  so path B becomes a symlink to directory A:
    [lib dir](./lib/) -> [link](./bin/lib)
    ./lib/ -> ./bin/lib
  - A must be an existing directory
  - B must be missing (symlink is created) or already a symlink resolving to A
    (if its form differs - relative vs absolute - it is replaced)
  - B pointing elsewhere, B being a real directory or a file -> error (nothing is changed)
  - path B ending with "/" while path A doesn't -> error
`;
  console.log(helpText.trim());
  process.exit(1);
}
function expandHome(filePath) {
  if (filePath === "~") {
    return os.homedir();
  }
  if (filePath.startsWith("~/") || filePath.startsWith("~\\")) {
    return path.join(os.homedir(), filePath.slice(2));
  }
  return filePath;
}
function extractPathString(token) {
  let cleaned = token.trim();
  const mdMatch = cleaned.match(/^\[.*?\]\((.*)\)$/);
  if (mdMatch) {
    cleaned = mdMatch[1].trim();
  }
  if ((cleaned.startsWith('"') && cleaned.endsWith('"')) || (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
    cleaned = cleaned.slice(1, -1);
  }
  return cleaned;
}
function parseArgs(args) {
  const options = {};
  let pwdFromNextArg = false;
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    if (arg === "--help" || arg === "-h") {
      options.help = true;
    } else if (arg === "--pwd") {
      const nextArg = args[i + 1];
      if (nextArg && !nextArg.startsWith("-")) {
        options.pwdOverride = nextArg;
        pwdFromNextArg = true;
        i++;
      } else {
        options.useCwd = true;
      }
    } else if (arg.startsWith("--pwd=")) {
      const value = arg.slice("--pwd=".length);
      if (value === "") {
        fail("Error: --pwd= requires a path (use --pwd alone for current working directory).");
      }
      options.pwdOverride = value;
      pwdFromNextArg = false;
    } else if (arg === "--unlink") {
      options.unlink = true;
    } else if (arg === "--absolute-symlink-dir") {
      options.absoluteSymlinkDir = true;
    } else if (arg === "--gitignore") {
      const nextArg = args[i + 1];
      if (nextArg && !nextArg.startsWith("-")) {
        options.gitignorePath = nextArg;
        i++;
      } else {
        fail("Error: --gitignore requires a file path argument.");
      }
    } else if (arg.startsWith("--gitignore=")) {
      const value = arg.slice("--gitignore=".length);
      if (value === "") {
        fail("Error: --gitignore requires a file path argument.");
      }
      options.gitignorePath = value;
    } else if (arg.startsWith("-")) {
      fail(`Error: Unknown option "${arg}" (use --help to list available options).`);
    } else if (options.configFile === void 0) {
      options.configFile = arg;
    } else {
      fail(`Error: Unexpected extra argument "${arg}" (config file already given: "${options.configFile}").`);
    }
  }
  if (options.configFile === void 0 && options.pwdOverride !== void 0 && pwdFromNextArg) {
    options.configFile = options.pwdOverride;
    options.pwdOverride = void 0;
    options.useCwd = true;
  }
  return options;
}
function resolveBaseDir(configFilePath, options) {
  if (options.pwdOverride) {
    const resolved = path.resolve(process.cwd(), expandHome(options.pwdOverride));
    return {
      baseDir: resolved,
      reason: `--pwd parameter with explicit path "${options.pwdOverride}"`,
    };
  }
  if (options.useCwd) {
    return {
      baseDir: process.cwd(),
      reason: "--pwd flag using current working directory",
    };
  }
  const configDir = path.dirname(path.resolve(process.cwd(), expandHome(configFilePath)));
  return {
    baseDir: configDir,
    reason: `config.md location (${configDir})`,
  };
}
function isReadable(p) {
  try {
    fs.accessSync(p, fs.constants.R_OK);
    return true;
  } catch {
    return false;
  }
}
function isWritable(p) {
  try {
    fs.accessSync(p, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}
function isWritableDir(p) {
  try {
    fs.accessSync(p, fs.constants.W_OK | fs.constants.X_OK);
    return true;
  } catch {
    return false;
  }
}
function sameRealPath(a, b) {
  try {
    return fs.realpathSync(a) === fs.realpathSync(b);
  } catch {
    return false;
  }
}
function sameInode(a, b) {
  return a.dev === b.dev && a.ino === b.ino;
}
function findExistingAncestor(p) {
  let curr = path.resolve(p);
  while (!fs.existsSync(curr) && curr !== path.dirname(curr)) {
    curr = path.dirname(curr);
  }
  return curr;
}
function lstatOrNull(p) {
  try {
    return fs.lstatSync(p);
  } catch {
    return null;
  }
}
function validateMissingBParent(resolvedB, statA) {
  const parentB = path.dirname(resolvedB);
  const ancestor = findExistingAncestor(parentB);
  const statAncestor = fs.statSync(ancestor);
  if (!statAncestor.isDirectory()) {
    return `Parent path "${ancestor}" is not a directory`;
  }
  if (ancestor === parentB) {
    if (!isWritableDir(parentB)) {
      return `Parent directory "${parentB}" is not writable`;
    }
  } else {
    if (!isWritableDir(ancestor)) {
      return `Cannot create parent directory for "${resolvedB}": Directory "${ancestor}" is not writable.`;
    }
  }
  if (statA !== null && statAncestor.dev !== statA.dev) {
    return `File A and file B are on different filesystems (hardlinks cannot cross filesystems): file B would land on "${ancestor}"`;
  }
  return null;
}
function replaceAtomically(resolvedB, create) {
  const tmpB = `${resolvedB}.hardlink_tmp_${process.pid}`;
  fs.rmSync(tmpB, { force: true });
  create(tmpB);
  try {
    fs.renameSync(tmpB, resolvedB);
  } catch (err) {
    fs.rmSync(tmpB, { force: true });
    throw err;
  }
}
function validateDirPair(pair) {
  const errA = (msg) => `Directory A [${pair.rawA}] error:
   ${msg}`;
  const errB = (msg) => `Symlink B [${pair.rawB}] error:
   ${msg}`;
  if (!fs.existsSync(pair.resolvedA)) {
    return errA(`Directory does not exist: "${pair.resolvedA}"`);
  }
  if (!fs.statSync(pair.resolvedA).isDirectory()) {
    return errA(`Path is not a directory (path A ends with "/"): "${pair.resolvedA}"`);
  }
  const lstatB = lstatOrNull(pair.resolvedB);
  if (lstatB === null) {
    const parentError = validateMissingBParent(pair.resolvedB, null);
    if (parentError === null) {
      return null;
    }
    return errB(parentError);
  }
  if (lstatB.isSymbolicLink()) {
    const current = fs.readlinkSync(pair.resolvedB);
    if (current === pair.symlinkTarget) {
      return null;
    }
    if (
      path.resolve(path.dirname(pair.resolvedB), current) === pair.resolvedA ||
      sameRealPath(pair.resolvedB, pair.resolvedA)
    ) {
      const parentB = path.dirname(pair.resolvedB);
      if (isWritableDir(parentB)) {
        return null;
      }
      return errB(`Parent directory "${parentB}" is not writable (needed to replace symlink B)`);
    }
    return errB(
      `Symlink points to "${current}" but expected "${pair.symlinkTarget}" (directory A: "${pair.resolvedA}")`
    );
  }
  if (lstatB.isDirectory()) {
    return errB(
      `Path is a real directory, not a symlink - no way to compare it with directory A, remove it manually if it should become a symlink: "${pair.resolvedB}"`
    );
  }
  return errB(`Path exists but is not a symlink: "${pair.resolvedB}"`);
}
function executeDirPair(pair, changedLabel) {
  const lstatB = lstatOrNull(pair.resolvedB);
  if (lstatB === null) {
    fs.mkdirSync(path.dirname(pair.resolvedB), { recursive: true });
    fs.symlinkSync(pair.symlinkTarget, pair.resolvedB, "dir");
    console.log(`   ${changedLabel}: Created symlink B -> "${pair.symlinkTarget}"`);
  } else {
    const current = fs.readlinkSync(pair.resolvedB);
    if (current === pair.symlinkTarget) {
      console.log(`   Already linked (symlink B -> "${current}")`);
    } else {
      replaceAtomically(pair.resolvedB, (tmpB) => fs.symlinkSync(pair.symlinkTarget, tmpB, "dir"));
      console.log(`   ${changedLabel}: Replaced symlink B "${current}" -> "${pair.symlinkTarget}"`);
    }
  }
  console.log(
    `   (B resolves to: ${fs.realpathSync(pair.resolvedB)}, directory A: ${fs.realpathSync(pair.resolvedA)})`
  );
}
function sameContent(fileA, sizeA, fileB, sizeB) {
  if (sizeA !== sizeB) {
    return false;
  }
  return fs.readFileSync(fileA).equals(fs.readFileSync(fileB));
}
function validateFilePair(pair) {
  const errA = (msg) => `File A [${pair.rawA}] error:
   ${msg}`;
  const errB = (msg) => `File B [${pair.rawB}] error:
   ${msg}`;
  if (pair.rawB.endsWith("/")) {
    return errB(
      `Path B ends with "/" (directory) but path A doesn't - add "/" to the end of path A to link directories`
    );
  }
  if (!fs.existsSync(pair.resolvedA)) {
    return errA(`File does not exist: "${pair.resolvedA}"`);
  }
  const statA = fs.statSync(pair.resolvedA);
  if (!statA.isFile()) {
    return errA(`Path is not a regular file: "${pair.resolvedA}"`);
  }
  if (!isReadable(pair.resolvedA)) {
    return errA(`File is not readable: "${pair.resolvedA}"`);
  }
  const lstatB = lstatOrNull(pair.resolvedB);
  if (lstatB === null) {
    const parentError = validateMissingBParent(pair.resolvedB, statA);
    return parentError === null ? null : errB(parentError);
  }
  const isSymlinkB = lstatB.isSymbolicLink();
  let statB;
  try {
    statB = fs.statSync(pair.resolvedB);
  } catch (err) {
    if (isSymlinkB) {
      return errB(
        `Path is a broken symlink (points to "${fs.readlinkSync(pair.resolvedB)}"), remove it manually: "${
          pair.resolvedB
        }"`
      );
    }
    return errB(`Cannot access path: "${pair.resolvedB}": ${err.message}`);
  }
  if (!statB.isFile()) {
    return errB(`Path is not a regular file: "${pair.resolvedB}"`);
  }
  if (!isSymlinkB && sameInode(statA, statB)) {
    return null;
  }
  if (!isReadable(pair.resolvedB)) {
    return errB(`File is not readable: "${pair.resolvedB}"`);
  }
  const parentOfB = path.dirname(pair.resolvedB);
  if (!isWritableDir(parentOfB)) {
    return errB(`Parent directory "${parentOfB}" is not writable (needed to replace file B)`);
  }
  if (statA.dev !== lstatB.dev) {
    return errB(
      `File A and file B are on different filesystems (hardlinks cannot cross filesystems): "${pair.resolvedA}" vs "${pair.resolvedB}"`
    );
  }
  if (!sameContent(pair.resolvedA, statA.size, pair.resolvedB, statB.size)) {
    return errB(`Content of file B does not match content of file A`);
  }
  return null;
}
function executeFilePair(pair, changedLabel) {
  const statA = fs.statSync(pair.resolvedA);
  const lstatB = lstatOrNull(pair.resolvedB);
  if (lstatB !== null) {
    if (!lstatB.isSymbolicLink() && sameInode(statA, lstatB)) {
      console.log(`   Already linked (inode A: ${statA.ino}, inode B: ${lstatB.ino})`);
      return;
    }
    replaceAtomically(pair.resolvedB, (tmpB) => fs.linkSync(pair.resolvedA, tmpB));
    const newStatB2 = fs.lstatSync(pair.resolvedB);
    const what = lstatB.isSymbolicLink() ? "symlink B" : "file B";
    console.log(
      `   ${changedLabel}: Replaced ${what} with hardlink to file A (inode A: ${statA.ino}, inode B: ${newStatB2.ino})`
    );
    return;
  }
  fs.mkdirSync(path.dirname(pair.resolvedB), { recursive: true });
  fs.linkSync(pair.resolvedA, pair.resolvedB);
  const newStatB = fs.lstatSync(pair.resolvedB);
  console.log(
    `   ${changedLabel}: Created hardlink from file A to file B (inode A: ${statA.ino}, inode B: ${newStatB.ino})`
  );
}
function unlinkPairs(pairs, unlinkedLabel) {
  let failures = 0;
  for (const pair of pairs) {
    if (pair.isDir) {
      continue;
    }
    let statA;
    try {
      statA = fs.statSync(pair.resolvedA);
    } catch {
      continue;
    }
    const lstatB = lstatOrNull(pair.resolvedB);
    if (lstatB === null || !statA.isFile() || !lstatB.isFile()) {
      continue;
    }
    if (!sameInode(statA, lstatB)) {
      continue;
    }
    const tempPath = `${pair.resolvedB}.unlink_tmp_${process.pid}_${Math.random().toString(36).slice(2)}`;
    try {
      fs.copyFileSync(pair.resolvedA, tempPath);
      fs.renameSync(tempPath, pair.resolvedB);
      const newStatB = fs.statSync(pair.resolvedB);
      console.log(`
${pair.rawLine}`);
      console.log(
        `   ${unlinkedLabel}: Disconnected hardlink, preserved independent file B (inode A: ${statA.ino}, inode B: ${newStatB.ino})`
      );
    } catch (err) {
      fs.rmSync(tempPath, { force: true });
      failures++;
      console.error(`Error unlinking "${pair.resolvedB}": ${err.message}`);
    }
  }
  return failures;
}
function toGitignoreEntry(gitignoreDir, resolvedB) {
  const rel = path.relative(gitignoreDir, resolvedB).split(path.sep).join("/");
  if (rel === "" || rel === ".." || rel.startsWith("../") || path.isAbsolute(rel)) {
    return null;
  }
  let entry = rel.replace(/[\\*?[]/g, "\\$&").replace(/ +$/, (spaces) => "\\ ".repeat(spaces.length));
  if (!entry.includes("/")) {
    entry = `/${entry}`;
  } else if (entry.startsWith("#") || entry.startsWith("!")) {
    entry = `\\${entry}`;
  }
  return entry;
}
function parseConfigFile(content, baseDir, absoluteSymlinkDir = false) {
  const lines = content.split(/\r?\n/);
  const pairs = [];
  for (const line of lines) {
    const trimmed = line.trim();
    if (trimmed === "") {
      continue;
    }
    const match = trimmed.match(/^(.*?)\s+->\s+(.*)$/);
    if (match) {
      const rawA = extractPathString(match[1]);
      const rawB = extractPathString(match[2]);
      const expandedA = expandHome(rawA);
      const expandedB = expandHome(rawB);
      const resolvedA = path.resolve(baseDir, expandedA);
      const resolvedB = path.resolve(baseDir, expandedB);
      const isDir = rawA.endsWith("/");
      let symlinkTarget = "";
      if (isDir) {
        symlinkTarget = absoluteSymlinkDir ? resolvedA : path.relative(path.dirname(resolvedB), resolvedA) || ".";
      }
      pairs.push({
        rawLine: line,
        rawA,
        rawB,
        resolvedA,
        resolvedB,
        isDir,
        symlinkTarget,
      });
    }
  }
  return pairs;
}
function updateGitignore(gitignoreFilePath, relativePathsToAdd) {
  let content = "";
  if (fs.existsSync(gitignoreFilePath)) {
    content = fs.readFileSync(gitignoreFilePath, "utf-8");
  }
  const startMarker = "# hardlink.ts vvv";
  const endMarker = "# hardlink.ts ^^^";
  const lines = content.split(/\r?\n/);
  const startIndex = lines.findIndex((l) => l.trim() === startMarker);
  const endIndex = lines.findIndex((l) => l.trim() === endMarker);
  const hasDelimiters = startIndex !== -1 && endIndex !== -1 && startIndex < endIndex;
  const added = [];
  relativePathsToAdd = [...new Set(relativePathsToAdd)];
  if (hasDelimiters) {
    const insideLines = lines.slice(startIndex + 1, endIndex).map((l) => l.trim());
    const toInsert = [];
    for (const relPath of relativePathsToAdd) {
      if (!insideLines.includes(relPath.trim())) {
        toInsert.push(relPath);
        added.push(relPath);
      }
    }
    if (toInsert.length > 0) {
      lines.splice(endIndex, 0, ...toInsert);
      fs.writeFileSync(gitignoreFilePath, lines.join("\n"), "utf-8");
      return { changed: true, added };
    }
    return { changed: false, added: [] };
  } else {
    const existingLines = lines.map((l) => l.trim());
    const toAppend = [];
    for (const relPath of relativePathsToAdd) {
      if (!existingLines.includes(relPath.trim())) {
        toAppend.push(relPath);
        added.push(relPath);
      }
    }
    if (toAppend.length > 0) {
      let newContent = content;
      if (newContent.length > 0 && !newContent.endsWith("\n")) {
        newContent += "\n";
      }
      newContent += toAppend.join("\n") + "\n";
      fs.writeFileSync(gitignoreFilePath, newContent, "utf-8");
      return { changed: true, added };
    }
    return { changed: false, added: [] };
  }
}
async function run(args) {
  const options = parseArgs(args);
  if (options.help || !options.configFile) {
    showHelp();
  }
  if (options.unlink && options.gitignorePath) {
    fail("Error: --unlink flag cannot be used together with --gitignore flag.");
  }
  const rawConfigPath = options.configFile;
  const configPath = path.resolve(process.cwd(), expandHome(rawConfigPath));
  const { baseDir, reason } = resolveBaseDir(rawConfigPath, options);
  console.log(`Resolved paths relative to: ${baseDir} (reason: ${reason})`);
  let resolvedGitignore;
  if (options.gitignorePath) {
    resolvedGitignore = path.resolve(process.cwd(), expandHome(options.gitignorePath));
    if (!fs.existsSync(resolvedGitignore)) {
      fail(`Error: Gitignore file "${options.gitignorePath}" does not exist: "${resolvedGitignore}"`);
    }
    const gitignoreStat = fs.statSync(resolvedGitignore);
    if (!gitignoreStat.isFile()) {
      fail(`Error: Gitignore path "${options.gitignorePath}" is not a file: "${resolvedGitignore}"`);
    }
    if (!isWritable(resolvedGitignore)) {
      fail(`Error: Gitignore file "${resolvedGitignore}" is not writable.`);
    }
  }
  if (!fs.existsSync(configPath)) {
    fail(`Error: Config file "${rawConfigPath}" does not exist.`);
  }
  let configStat;
  try {
    configStat = fs.statSync(configPath);
  } catch (err) {
    fail(`Error: Cannot access config file "${rawConfigPath}": ${err.message}`);
  }
  if (!configStat.isFile()) {
    fail(`Error: Config path "${rawConfigPath}" is not a file.`);
  }
  if (!isReadable(configPath)) {
    fail(`Error: Config file "${rawConfigPath}" is not readable.`);
  }
  const content = fs.readFileSync(configPath, "utf-8");
  const pairs = parseConfigFile(content, baseDir, options.absoluteSymlinkDir === true);
  const isTTY = process.stdout.isTTY;
  const green = isTTY ? "\x1B[32m" : "";
  const reset = isTTY ? "\x1B[0m" : "";
  if (options.unlink) {
    const failures = unlinkPairs(pairs, `${green}UNLINKED${reset}`);
    if (failures > 0) {
      fail(`Error: failed to unlink ${failures} pair(s) - see errors above.`);
    }
    return;
  }
  const errors = [];
  const gitignoreEntries = [];
  const seenB = /* @__PURE__ */ new Map();
  for (const pair of pairs) {
    const labelB = pair.isDir ? "Symlink B" : "File B";
    const first = seenB.get(pair.resolvedB);
    if (first === void 0) {
      seenB.set(pair.resolvedB, pair);
    } else if (first.resolvedA !== pair.resolvedA || first.isDir !== pair.isDir) {
      errors.push(
        `${labelB} [${pair.rawB}] error:
   Path B is used by more than one pair with different path A: [${first.rawA}] and [${pair.rawA}]: "${pair.resolvedB}"`
      );
      continue;
    }
    const pairError = pair.isDir ? validateDirPair(pair) : validateFilePair(pair);
    if (pairError !== null) {
      errors.push(pairError);
      continue;
    }
    if (resolvedGitignore) {
      const entry = toGitignoreEntry(path.dirname(resolvedGitignore), pair.resolvedB);
      if (entry === null) {
        errors.push(
          `${labelB} [${pair.rawB}] error:
   Path is outside of the directory of gitignore file "${resolvedGitignore}" - gitignore cannot ignore it: "${pair.resolvedB}"`
        );
        continue;
      }
      gitignoreEntries.push(entry);
    }
  }
  if (errors.length > 0) {
    fail(errors.join("\n\n") + "\n");
  }
  for (const pair of pairs) {
    console.log(`
${pair.rawLine}`);
    try {
      if (pair.isDir) {
        executeDirPair(pair, `${green}CHANGED${reset}`);
      } else {
        executeFilePair(pair, `${green}CHANGED${reset}`);
      }
    } catch (err) {
      fail(
        `Error: failed on line "${pair.rawLine.trim()}": ${err.message}
   Lines above were already processed, this line and lines below were not.`
      );
    }
  }
  if (resolvedGitignore) {
    console.log(`
Gitignore check: "${resolvedGitignore}"`);
    const { changed, added } = updateGitignore(resolvedGitignore, gitignoreEntries);
    if (changed) {
      console.log(`   ${green}CHANGED${reset}: Added to gitignore:`);
      for (const entry of added) {
        console.log(`      + ${entry}`);
      }
    } else {
      console.log(`   No changes: all target paths already present in gitignore`);
    }
  }
}
function isMain() {
  if (!process.argv[1]) {
    return false;
  }
  const self = fileURLToPath(import.meta.url);
  try {
    return fs.realpathSync(process.argv[1]) === fs.realpathSync(self);
  } catch {
    return path.resolve(process.argv[1]) === self;
  }
}
if (isMain()) {
  run(process.argv.slice(2)).catch((err) => {
    console.error(err instanceof Error ? err.message : String(err));
    process.exit(1);
  });
}
export {
  HardlinkError,
  expandHome,
  extractPathString,
  parseArgs,
  parseConfigFile,
  resolveBaseDir,
  run,
  showHelp,
  toGitignoreEntry,
  updateGitignore,
};
