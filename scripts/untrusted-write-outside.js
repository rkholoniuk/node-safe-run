// Attempts to write files outside the current project to exercise write guards.
const fs = require("fs");
const path = require("path");

const targets = [
  path.resolve("/etc/node-safe-run-owned.txt"),
  path.join(process.env.HOME || "/tmp", "node-safe-run-home.txt"),
  path.resolve("/tmp/node-safe-run-outside.txt"),
];

for (const target of targets) {
  try {
    fs.writeFileSync(target, "untrusted write attempt\n", { flag: "a" });
    console.log(`WROTE: ${target}`);
  } catch (err) {
    console.error(`BLOCKED: ${target} -> ${err.message}`);
  }
}

