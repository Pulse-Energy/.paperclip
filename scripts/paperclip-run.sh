#!/bin/zsh
#
# paperclip-run.sh — foreground runner for the local Paperclip control-plane server.
#
# This is the process that launchd (com.pulse-energy.paperclip) keeps alive.
# It must run in the FOREGROUND (no nohup/&/daemonizing) so launchd can track,
# restart, and stop it. Do not background anything in here.
#
# Why this exists: if agents inherit an unreachable control-plane URL (e.g. a stale
# ngrok domain with the wrong :3100 port), every agent API call hangs ~300s and
# heartbeats stall.
#
# NOTE: the export below is a HARMLESS FALLBACK ONLY. It is NOT the real control knob.
# At startup, @paperclipai/server OVERWRITES process.env.PAPERCLIP_RUNTIME_API_URL
# from config.json via choosePrimaryRuntimeApiUrl(), whose precedence is:
#     auth.publicBaseUrl  ->  server.allowedHostnames[0] (+ :port)  ->  bind host
# With baseUrlMode "auto" (publicBaseUrl unset) it uses allowedHostnames[0]. So the
# REAL fix lives in ~/.paperclip/instances/default/config.json: keep "127.0.0.1"
# as the first entry of server.allowedHostnames. (ps shows this export's value, not
# the runtime-computed one — don't trust ps to verify the agent URL.)
# See pulse-energy-docs/paperclip-server.md -> "Where the agent URL actually comes from".

# --- Agent-facing control-plane URL (fallback only; config.json is authoritative) ---
export PAPERCLIP_RUNTIME_API_URL="http://127.0.0.1:3100"

# --- PATH (launchd starts with a minimal env: /usr/bin:/bin:/usr/sbin:/sbin) ---
# We must reconstruct enough of the login-shell PATH that the agent ADAPTERS can
# find the CLIs they shell out to:
#   - `cursor` adapter   -> `agent`  (cursor-agent), in ~/.local/bin
#   - `claude_local`     -> `claude`, in ~/.local/bin
# If ~/.local/bin is missing here, cursor runs fail with:
#   Command not found in PATH: "agent"   (stopReason: adapter_failed)
export NVM_DIR="$HOME/.nvm"
# Prefer the highest installed nvm node; fall back to sourcing nvm.sh.
NODE_BIN="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -1)"
[ -z "$NODE_BIN" ] && [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # shellcheck disable=SC1091

export PATH="$HOME/.local/bin:${NODE_BIN:+$NODE_BIN:}$HOME/.pyenv/shims:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

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
