// legacyFetch is being replaced by apiClient. A file may not contain more
// legacyFetch calls than legacy-api-baseline.json allows it, so new calls fail
// CI. Run with --update to rewrite the baseline from the current tree.
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const baselinePath = join(root, "legacy-api-baseline.json");

function* walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (entry.isDirectory()) yield* walk(path);
    else if (/\.tsx?$/.test(entry.name)) yield path;
  }
}

const counts = {};
for (const file of walk(join(root, "src"))) {
  const calls = readFileSync(file, "utf8").match(/\blegacyFetch\(/g)?.length ?? 0;
  if (calls > 0) counts[relative(root, file)] = calls;
}

if (process.argv.includes("--update")) {
  const sorted = Object.fromEntries(Object.entries(counts).sort());
  writeFileSync(baselinePath, JSON.stringify(sorted, null, 2) + "\n");
  console.log(`baseline updated: ${Object.keys(sorted).length} files`);
  process.exit(0);
}

const baseline = JSON.parse(readFileSync(baselinePath, "utf8"));
let failed = false;
for (const [file, calls] of Object.entries(counts)) {
  const allowed = baseline[file] ?? 0;
  if (calls > allowed) {
    console.error(`${file}: ${calls} legacyFetch calls, baseline allows ${allowed}`);
    failed = true;
  }
}
const total = Object.values(counts).reduce((a, b) => a + b, 0);
console.log(failed ? "legacy API check failed" : `legacy API check passed: ${total} calls`);
process.exit(failed ? 1 : 0);
