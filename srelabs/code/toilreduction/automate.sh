#!/usr/bin/env bash
# setup_lab6.sh
# End-to-end automation for Lab 06: Toil Reduction with Automated Service Recovery
# - Installs Docker/docker-compose (if needed)
# - Runs nginx container
# - Creates a self-healing check_nginx.sh script and schedules it via cron
# - Idempotent: safe to re-run
# Usage: chmod +x setup_lab6.sh && ./setup_lab6.sh
set -euo pipefail

WORKDIR="$HOME/sre-foundations/lab5-toil"
SCRIPT_PATH="$WORKDIR/check_nginx.sh"
LOGFILE="$WORKDIR/nginx_auto_recovery.log"
CRON_MARKER="# SRE-LAB6-AUTORECOVER"
CRON_ENTRY="*/2 * * * * $SCRIPT_PATH >> $WORKDIR/cron_run.log 2>&1"

# Helper: detect package manager
detect_pkg_mgr() {
  if command -v yum >/dev/null 2>&1; then
    echo "yum"
  elif command -v apt-get >/dev/null 2>&1; then
    echo "apt"
  else
    echo "unknown"
  fi
}

PKG_MGR=$(detect_pkg_mgr)
echo "Detected package manager: $PKG_MGR"

install_if_missing() {
  local cmd=$1 pkg=$2
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Installing $pkg..."
    if [ "$PKG_MGR" = "yum" ]; then
      sudo yum install -y "$pkg"
    elif [ "$PKG_MGR" = "apt" ]; then
      sudo apt-get update -y
      sudo apt-get install -y "$pkg"
    else
      echo "Unsupported package manager. Please install $pkg manually."
      exit 1
    fi
  else
    echo "$pkg already installed."
  fi
}

# 1) Install Docker if missing
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found — installing..."
  if [ "$PKG_MGR" = "yum" ]; then
    sudo yum update -y
    sudo yum install -y docker
  elif [ "$PKG_MGR" = "apt" ]; then
    sudo apt-get update -y
    sudo apt-get install -y docker.io
  else
    echo "Please install Docker manually on this platform."
    exit 1
  fi
else
  echo "Docker is already installed: $(docker --version)"
fi

# Start and enable Docker
echo "Starting docker..."
sudo systemctl enable --now docker

# 2) Add current user to docker group (idempotent)
USER_NAME="${SUDO_USER:-$USER}"
echo "Adding $USER_NAME to docker group (may require re-login to take full effect)..."
sudo usermod -aG docker "$USER_NAME" || true
# Apply group changes to current session if possible
if command -v newgrp >/dev/null 2>&1; then
  newgrp docker <<'NG' || true
# noop: newgrp executed to apply docker group; continue
NG
fi

# 3) Pull and run nginx container idempotently
echo "Ensuring nginx container is running..."
# Reuse port 80 on host; if already occupied, will detect and continue
if docker ps --format '{{.Names}}' | grep -qx nginx 2>/dev/null; then
  echo "Container 'nginx' already running."
else
  # If stopped container exists, remove it then run fresh
  if docker ps -a --format '{{.Names}}' | grep -qx nginx 2>/dev/null; then
    echo "Found existing stopped 'nginx' container — removing and recreating..."
    docker rm -f nginx || true
  fi
  echo "Running nginx container..."
  docker pull nginx:latest
  docker run -d --name nginx -p 80:80 --restart unless-stopped nginx:latest
fi

# 4) Create working directory
mkdir -p "$WORKDIR"
echo "Working directory: $WORKDIR"

# 5) Create the check_nginx.sh script (idempotent content)
cat > "$SCRIPT_PATH" <<'SH'
#!/usr/bin/env bash
# Auto-recovery script for nginx Docker container
LOG="$HOME/sre-foundations/lab5-toil/nginx_auto_recovery.log"
DOCKER_BIN="$(command -v docker || true)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# Ensure docker binary exists
if [ -z "$DOCKER_BIN" ]; then
  echo "$DATE: ERROR - docker not found in PATH" >> "$LOG"
  exit 1
fi

# Function to log message with level
log() {
  local level="$1"; shift
  echo "$DATE: $level - $*" >> "$LOG"
}

# Create log file if not exists
touch "$LOG" || true

# Check if container named 'nginx' is running
if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx nginx; then
  echo "$(date '+%Y-%m-%d %H:%M:%S'): WARN - nginx container not running. Attempting recovery..." >> "$LOG"

  # If a stopped container exists, start it
  if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -qx nginx; then
    if $DOCKER_BIN start nginx >/dev/null 2>&1; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): INFO - nginx container started successfully." >> "$LOG"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - failed to start existing nginx container." >> "$LOG"
    fi
  else
    # No container exists; create and run it
    if $DOCKER_BIN run -d --name nginx -p 80:80 --restart unless-stopped nginx:latest >/dev/null 2>&1; then
      echo "$(date '+%Y-%m-%d %H:%M:%S'): INFO - nginx container created and started." >> "$LOG"
    else
      echo "$(date '+%Y-%m-%d %H:%M:%S'): ERROR - failed to create/start nginx container." >> "$LOG"
    fi
  fi
else
  echo "$(date '+%Y-%m-%d %H:%M:%S'): OK - nginx is running." >> "$LOG"
fi
SH

# 6) Make script executable
chmod +x "$SCRIPT_PATH"
echo "Created auto-recovery script at $SCRIPT_PATH"

# 7) Run script once now to generate initial log entry
echo "Running the check script once to validate..."
"$SCRIPT_PATH" || true
sleep 1
echo "Tail of log:"
tail -n 10 "$LOGFILE" || true

# 8) Ensure cron (cronie) is installed and enabled
if ! command -v crontab >/dev/null 2>&1; then
  echo "Installing cron..."
  if [ "$PKG_MGR" = "yum" ]; then
    sudo yum install -y cronie
    sudo systemctl enable --now crond
  elif [ "$PKG_MGR" = "apt" ]; then
    sudo apt-get install -y cron
    sudo systemctl enable --now cron
  else
    echo "Please install cron manually."
    exit 1
  fi
else
  echo "crontab available."
fi

# 9) Install cron job idempotently
# We will add a comment marker and add the entry only if not present
CRON_TMP=$(mktemp)
crontab -l 2>/dev/null || true > "$CRON_TMP"
if grep -Fq "$CRON_MARKER" "$CRON_TMP"; then
  echo "Cron job already installed."
else
  echo "Adding cron job to run recovery script every 2 minutes..."
  {
    cat "$CRON_TMP"
    echo ""
    echo "$CRON_MARKER"
    echo "$CRON_ENTRY"
  } | crontab -
  echo "Cron job installed."
fi
rm -f "$CRON_TMP"

# 10) Quick validation instructions printed to user
cat <<EOF

=== SETUP COMPLETE ===

Key locations:
 - Auto-recovery script: $SCRIPT_PATH
 - Recovery log:         $LOGFILE
 - Cron job:             runs every 2 minutes (added with marker: $CRON_MARKER)
 - Container name:       nginx

Useful commands to validate behavior:

# Show containers
docker ps --filter "name=nginx"

# View recent recovery log entries
tail -n 50 "$LOGFILE"

# Manually stop the nginx container to simulate failure:
docker stop nginx

# Immediately run the check script to verify recovery:
$SCRIPT_PATH

# Or wait up to 2 minutes for cron to run the check automatically, then:
tail -n 50 "$LOGFILE"
docker ps --filter "name=nginx"

# To view cron output log (if any):
ls -l $WORKDIR/cron_run.log || true
tail -n 50 $WORKDIR/cron_run.log || true

Cleanup (optional):
  # Remove cron entry:
  crontab -l | sed '/$CRON_MARKER/,+1d' | crontab -

  # Stop and remove nginx container
  docker rm -f nginx || true

  # Remove created files
  rm -rf "$WORKDIR"

EOF

echo "Done."

