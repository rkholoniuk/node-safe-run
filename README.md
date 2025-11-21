# 🔐 node-safe-run  
### Secure Node.js execution with automatic permission enforcement

`node-safe-run` is a Node.js launcher that activates the built-in
permission model by default, blocks unsafe child processes, restricts filesystem
access, and prevents malicious NPM postinstall scripts, hidden VS Code extension
nodes, or obfuscated malware from executing arbitrary shell commands.

### ✅ Supported Node.js Versions
- **Node.js 24.x** — Full permission support (recommended)
- **Node.js 22.x** — Full permission support

A small shim to run Node with the permission model enabled by default, log executions, and deny dangerous capabilities.

Quick links
- Run wrapper: [bin/node-safe-run](bin/node-safe-run)
- Install helper: [bin/node-safe-run-wrapper.sh](bin/node-safe-run-wrapper.sh)
- Malicious samples (in `scripts/`):
  - [scripts/untrusted-script.js](scripts/untrusted-script.js) — runs installers
  - [scripts/untrusted-child-process.js](scripts/untrusted-child-process.js) — spawns `whoami`
  - [scripts/untrusted-write-outside.js](scripts/untrusted-write-outside.js) — writes outside the project

Status
- Wrapper enforces `--permission` with deny-by-default.
- Installer can install/uninstall for nvm-managed Node.

Why use this
- Deny-by-default security model for untrusted scripts.
- Transparent to tooling (VS Code, editors) because it wraps the `node` binary.
- Execution logging to help audits: default log at `~/.node_exec_log`.

Install / uninstall / status (nvm node only)
- Install: `./bin/node-safe-run-wrapper.sh install`
- Status: `./bin/node-safe-run-wrapper.sh status`
- Uninstall: `./bin/node-safe-run-wrapper.sh uninstall`

Usage
- Run a script with safe defaults: `node-safe-run app.js`
- Inline script: `node-safe-run -e "console.log('hello')"`

Environment configuration
- NODE_SAFE_RUN_NODE_BIN — override which `node` to use (default: `which node`)
- NODE_SAFE_RUN_LOG_FILE — set log file (default: `~/.node_exec_log`)
- NODE_UNSAFE_OK=1 — bypass safety and run node directly
- NODE_SAFE_RUN_ALLOW_FS_READ — colon-separated allowed read paths (default: `.`)
- NODE_SAFE_RUN_ALLOW_FS_WRITE — colon-separated allowed write paths (default: none)
- NODE_SAFE_RUN_ALLOW_WASI=1 — allow WASI if set to `1`

Examples
- Allow reads in projects and /tmp:
  NODE_SAFE_RUN_ALLOW_FS_READ="/Users/you/projects:/tmp" node-safe-run server.js

- Allow write to /tmp:
  NODE_SAFE_RUN_ALLOW_FS_READ="." \
  NODE_SAFE_RUN_ALLOW_FS_WRITE="/tmp" \
  node-safe-run script.js

Proven sample runs (default settings)
- Child process denied: `./bin/node-safe-run scripts/untrusted-child-process.js`
- Writes denied (except maybe /tmp if allowed): `./bin/node-safe-run scripts/untrusted-write-outside.js`
- Installer download attempt: `./bin/node-safe-run scripts/untrusted-script.js`

Security model
- The wrapper adds `--permission` and grants only the explicit permissions set via environment variables.
- By default the wrapper does NOT grant child-processes, workers, addons, or native modules.
- To bypass temporarily for trusted workflows use `NODE_UNSAFE_OK=1`.

Notes about the installer
- The installer script [bin/node-safe-run-wrapper.sh](bin/node-safe-run-wrapper.sh) only operates on nvm-managed node installations (it refuses to modify system node).
- The installer moves `/path/to/node` → `/path/to/node-real` and writes a wrapper at `/path/to/node`.
