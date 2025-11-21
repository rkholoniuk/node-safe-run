// Attempts to spawn a child process to verify the permission model blocks it.
// Default command is `whoami -a`, override via args: node scripts/untrusted-child-process.js <cmd> [...args]
const { spawn } = require("child_process");

const [cmd = "whoami", ...args] = process.argv.slice(2);
console.log(`Attempting to spawn: ${cmd} ${args.join(" ")}`.trim());

const child = spawn(cmd, args.length ? args : ["-a"], { stdio: "inherit" });

child.on("error", (err) => {
  console.error("Spawn blocked or failed:", err.message);
  process.exitCode = 1;
});

child.on("exit", (code, signal) => {
  if (signal) {
    console.error(`Child terminated by signal ${signal}`);
  } else {
    console.log(`Child exited with code ${code}`);
  }
});
