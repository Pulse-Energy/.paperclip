#!/bin/zsh
#
# paperclipctl.sh — manage the local Paperclip control-plane server via launchd.
#
# Usage:
#   ./paperclipctl.sh install     # load the LaunchAgent (also starts it)
#   ./paperclipctl.sh uninstall   # unload the LaunchAgent (stops + disables autostart)
#   ./paperclipctl.sh start       # start (loads if needed)
#   ./paperclipctl.sh stop        # stop (unloads so KeepAlive won't relaunch)
#   ./paperclipctl.sh restart     # restart in place
#   ./paperclipctl.sh status      # launchd state + health + listeners
#   ./paperclipctl.sh logs        # follow the server log (Ctrl-C to exit)
#   ./paperclipctl.sh url         # print the agent-facing API URL in use
#
# Notes:
# - This is a per-user LaunchAgent (gui domain). It starts at login and is kept
#   alive by launchd. It does NOT require sudo.
# - "stop" unloads the agent because KeepAlive=true would otherwise relaunch a
#   simply-killed process.

set -u

LABEL="com.pulse-energy.paperclip"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
LOG="/Users/tonystark/desk/projects/pulse-energy/logs/paperclip-server.log"
HEALTH_URL="http://127.0.0.1:3100/api/health"
RUNTIME_API_URL="http://127.0.0.1:3100"
DOMAIN="gui/$(id -u)"
SERVICE="${DOMAIN}/${LABEL}"

is_loaded() { launchctl print "$SERVICE" >/dev/null 2>&1; }

# Stop any Paperclip server that is NOT managed by launchd (e.g. a manual
# `npx paperclipai run` or an old daemonized instance), to avoid port conflicts.
kill_stray() {
  local pids
  pids="$(pgrep -f 'paperclipai run' 2>/dev/null || true)"
  [ -z "$pids" ] && return 0
  echo "[paperclipctl] stopping stray (non-launchd) paperclipai run: $pids"
  # SIGINT first (graceful: lets it shut embedded postgres down), then SIGTERM.
  kill -INT $pids 2>/dev/null || true
  sleep 3
  pids="$(pgrep -f 'paperclipai run' 2>/dev/null || true)"
  [ -n "$pids" ] && { kill -TERM $pids 2>/dev/null || true; sleep 2; }
}

cmd_install() {
  kill_stray
  launchctl bootstrap "$DOMAIN" "$PLIST" 2>/dev/null \
    && echo "[paperclipctl] loaded $LABEL" \
    || { echo "[paperclipctl] bootstrap failed (already loaded?); enabling + kickstarting"; launchctl enable "$SERVICE" 2>/dev/null; launchctl kickstart -k "$SERVICE"; }
  wait_healthy
}

cmd_uninstall() {
  launchctl bootout "$DOMAIN" "$PLIST" 2>/dev/null \
    && echo "[paperclipctl] unloaded $LABEL" \
    || echo "[paperclipctl] not loaded"
}

cmd_start() {
  if is_loaded; then
    launchctl kickstart "$SERVICE" && echo "[paperclipctl] started (was loaded)"
  else
    cmd_install
  fi
  wait_healthy
}

cmd_stop() {
  # Unload so KeepAlive does not immediately relaunch the process.
  cmd_uninstall
}

cmd_restart() {
  if is_loaded; then
    launchctl kickstart -k "$SERVICE" && echo "[paperclipctl] restarted"
  else
    cmd_install
  fi
  wait_healthy
}

wait_healthy() {
  local i
  for i in $(seq 1 30); do
    if curl -sf -m 3 "$HEALTH_URL" >/dev/null 2>&1; then
      echo "[paperclipctl] healthy: $HEALTH_URL"
      return 0
    fi
    sleep 1
  done
  echo "[paperclipctl] WARNING: not healthy after 30s — check: $0 logs"
  return 1
}

cmd_status() {
  echo "=== launchd ($SERVICE) ==="
  if is_loaded; then
    launchctl print "$SERVICE" 2>/dev/null | grep -E '^\s*(state|pid|last exit code|program =)' || echo "(loaded)"
  else
    echo "not loaded"
  fi
  echo "=== health ==="
  curl -sf -m 5 "$HEALTH_URL" && echo " <- OK" || echo "DOWN"
  echo "=== processes ==="
  pgrep -fl 'paperclipai run' || echo "(no paperclipai run process)"
  echo "=== listeners ==="
  lsof -nP -iTCP:3100 -sTCP:LISTEN 2>/dev/null | tail -1 || echo "3100 free"
  lsof -nP -iTCP:54329 -sTCP:LISTEN 2>/dev/null | tail -1 || echo "54329 (postgres) free"
  echo "=== agent-facing URL ==="
  echo "PAPERCLIP_RUNTIME_API_URL=$RUNTIME_API_URL"
}

cmd_logs() { echo "[paperclipctl] tailing $LOG (Ctrl-C to stop)"; tail -n 80 -f "$LOG"; }
cmd_url()  { echo "$RUNTIME_API_URL"; }

case "${1:-}" in
  install)   cmd_install ;;
  uninstall) cmd_uninstall ;;
  start)     cmd_start ;;
  stop)      cmd_stop ;;
  restart)   cmd_restart ;;
  status)    cmd_status ;;
  logs)      cmd_logs ;;
  url)       cmd_url ;;
  *) echo "Usage: $0 {install|uninstall|start|stop|restart|status|logs|url}"; exit 2 ;;
esac
