#!/usr/bin/env bash
set -euo pipefail

# Node Safe Run Wrapper
# Usage:
#   ./node-safe-run-wrapper.sh install
#   ./node-safe-run-wrapper.sh uninstall
#   ./node-safe-run-wrapper.sh status

# ---- Helpers ---------------------------------------------------------------

die() {
  echo "ERROR: $*" >&2
  exit 1
}

info() {
  echo "[node-safe-run-wrapper] $*"
}

get_node_path() {
  local node_path
  node_path="$(command -v node || true)"
  if [[ -z "$node_path" ]]; then
    die "Could not find 'node' in PATH."
  fi
  echo "$node_path"
}

get_node_dir() {
  local node_path
  node_path="$(get_node_path)"
  dirname "$node_path"
}

ensure_nvm_node() {
  local node_path
  node_path="$(get_node_path)"
  # Extra safety: only touch nvm-managed node binaries
  if [[ "$node_path" != "$HOME/.nvm/"* ]]; then
    die "Detected node at '$node_path' which is not under \$HOME/.nvm/. Refusing to modify (to avoid breaking system node)."
  fi
}

# ---- Actions ---------------------------------------------------------------

install_wrapper() {
  ensure_nvm_node
  local node_dir node_path real_node wrapper_node

  node_dir="$(get_node_dir)"
  node_path="$(get_node_path)"
  real_node="$node_dir/node-real"
  wrapper_node="$node_dir/node"

  # If node-real already exists, assume wrapper is installed
  if [[ -x "$real_node" ]]; then
    info "Wrapper already installed at: $wrapper_node"
    info "Real node binary: $real_node"
    exit 0
  fi

  info "Installing Node safe wrapper..."
  info "Detected node at: $node_path"
  info "Node directory:   $node_dir"

  # Move actual node to node-real
  mv "$wrapper_node" "$real_node"

  # Create wrapper script
  cat > "$wrapper_node" <<'EOF'
#!/usr/bin/env bash

# Node Safe Wrapper
# Logs executions and enforces the permission model.

REAL_NODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_NODE="$REAL_NODE_DIR/node-real"
LOG_FILE="$HOME/.node_exec_log"

# 1) Log every Node execution
{
  echo "==== $(date) ===="
  echo "PID: $$"
  echo "PPID: $PPID"
  echo "CWD: $(pwd)"
  echo "CMD: $0"
  echo "ARGS: $*"
  echo
} >> "$LOG_FILE" 2>/dev/null || true

# 2) Bypass safety if NODE_UNSAFE_OK=1
if [[ "${NODE_UNSAFE_OK:-0}" == "1" ]]; then
  exec "$REAL_NODE" "$@"
  exit $?
fi

# --- Permission feature detection -----------------------------------------
supports_permission() {
  # Check via help output
  if "$REAL_NODE" --help 2>/dev/null | grep -q -- '--permission'; then
    return 0
  else
    return 1
  fi
}

# 3) Safe mode: enable permission model.
# By default, when --permission is enabled:
#   - FS is denied unless explicitly allowed
#   - Child processes are denied unless --allow-child-process is used
# Here we allow read access to the current working directory only.
if supports_permission; then
  # Safe execution with Node permissions enabled
  exec "$REAL_NODE" \
    --permission \
    --allow-fs-read=. \
    "$@"
else
  # Fallback if the Node build lacks permission support
  {
    echo "[node-safe-run] WARNING: Node at '${REAL_NODE}' does NOT support '--permission'."
    echo "[node-safe-run] skip execution."
  } >&2
  exit 1
fi
EOF

  chmod +x "$wrapper_node"

  info "Wrapper installiert."
  info "Real node moved to: $real_node"
  info "Wrapper script:     $wrapper_node"
  info "Log file:           $HOME/.node_exec_log"
  echo
  info "If something breaks, you can temporarily bypass with:"
  echo "  NODE_UNSAFE_OK=1 node your-script.js"
}

uninstall_wrapper() {
  ensure_nvm_node
  local node_dir node_path real_node wrapper_node

  node_dir="$(get_node_dir)"
  node_path="$(get_node_path)"
  real_node="$node_dir/node-real"
  wrapper_node="$node_dir/node"

  if [[ ! -x "$real_node" ]]; then
    die "No node-real found at '$real_node'. Wrapper does not seem to be installed."
  fi

  info "Uninstalling Node safe wrapper..."
  info "Restoring real node from: $real_node"

  rm -f "$wrapper_node"
  mv "$real_node" "$wrapper_node"
  chmod +x "$wrapper_node"

  info "Wrapper removed. 'node' restored to original binary."
}

status_wrapper() {
  local node_dir node_path real_node wrapper_node

  node_path="$(get_node_path)"
  node_dir="$(dirname "$node_path")"
  real_node="$node_dir/node-real"
  wrapper_node="$node_dir/node"

  echo "node path: $node_path"
  echo "node dir:  $node_dir"

  if [[ -x "$real_node" ]]; then
    echo "Status: SAFE WRAPPER INSTALLED"
    echo "  real binary: $real_node"
    echo "  wrapper:     $wrapper_node"
    echo "  log file:    $HOME/.node_exec_log"
    # Quick check if wrapper looks correct
    if grep -q 'Node Safe Wrapper' "$wrapper_node" 2>/dev/null; then
      echo "  wrapper script signature: OK"
    else
      echo "  WARNING: wrapper exists but does not look like this script's wrapper."
    fi
  else
    echo "Status: NO WRAPPER DETECTED"
    echo "  'node' is likely the real binary at: $node_path"
  fi
}

# ---- Main ------------------------------------------------------------------

cmd="${1:-}"

case "$cmd" in
  install)
    install_wrapper
    ;;
  uninstall)
    uninstall_wrapper
    ;;
  status)
    status_wrapper
    ;;
  *)
    echo "Usage: $0 {install|uninstall|status}"
    exit 1
    ;;
esac