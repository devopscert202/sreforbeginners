#!/bin/bash
# check_nginx.sh - auto-recover nginx Docker container
# Writes logs to $LOG and attempts to start/create nginx container if missing.

LOG="$HOME/sre-foundations/lab5-toil/nginx_auto_recovery.log"
mkdir -p "$HOME/sre-foundations/lab5-toil"
DOCKER_BIN="$(command -v docker || true)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# Ensure docker binary exists
if [ -z "$DOCKER_BIN" ]; then
  echo "$DATE: ERROR - docker not found in PATH" >> "$LOG"
  exit 1
fi

# Check if container named 'nginx' is running
if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx nginx; then
  echo "$DATE: WARN  - nginx container not running. Attempting recovery..." >> "$LOG"

  # If a stopped container exists, start it
  if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -qx nginx; then
    if $DOCKER_BIN start nginx >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container started successfully." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to start existing nginx container." >> "$LOG"
    fi
  else
    # No container exists; create and run it
    if $DOCKER_BIN run -d --name nginx -p 80:80 nginx:latest >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container created and started." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to create/start nginx container." >> "$LOG"
    fi
  fi
else
  echo "$DATE: OK    - nginx is running." >> "$LOG"
fi
