#!/bin/zsh
#
# paperclip-run.sh — foreground runner for the local Paperclip control-plane server.
#
# This is the process that launchd (com.pulse-energy.paperclip) keeps alive.
# It must run in the FOREGROUND (no nohup/&/daemonizing) so launchd can track,
# restart, and stop it. Do not background anything in here.
#
# Why this exists: agents read PAPERCLIP_RUNTIME_API_URL from the server's
# environment and inherit it as their PAPERCLIP_API_URL. If that points at an
# unreachable host (e.g. a stale ngrok tunnel, or an ngrok domain with the wrong
# :3100 port), every agent API call hangs ~300s and heartbeats stall. Pinning it
# to loopback keeps all local agents talking to the server directly.

# --- Agent-facing control-plane URL (THE important bit) -----------------------
export PAPERCLIP_RUNTIME_API_URL="http://127.0.0.1:3100"

# --- Put an nvm-managed node/npx on PATH (launchd starts with a minimal env) --
export NVM_DIR="$HOME/.nvm"
# Prefer the highest installed nvm node; fall back to sourcing nvm.sh.
NODE_BIN="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -1)"
if [ -n "$NODE_BIN" ]; then
  export PATH="$NODE_BIN:$PATH"
elif [ -s "$NVM_DIR/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "$NVM_DIR/nvm.sh"
fi
# Common Homebrew + system paths as a final safety net.
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"

cd "$HOME"

echo "[paperclip-run] $(date '+%Y-%m-%d %H:%M:%S') starting | node=$(command -v node) | PAPERCLIP_RUNTIME_API_URL=$PAPERCLIP_RUNTIME_API_URL"

# IMPORTANT: `paperclipai run` shuts down cleanly (incl. its embedded Postgres)
# on SIGINT, but does not reliably on SIGTERM. launchd sends SIGTERM when it
# stops/unloads the job, so we run the server as a child and trap SIGTERM/SIGINT
# to forward a SIGINT — guaranteeing a graceful shutdown and avoiding an
# orphaned Postgres / stale postmaster.pid.
npx --yes paperclipai run &
child=$!

trap 'kill -INT "$child" 2>/dev/null' TERM INT

wait "$child"
status=$?

# If wait returned because we were signalled, give the child time to exit fully.
while kill -0 "$child" 2>/dev/null; do sleep 0.5; done

exit "$status"
