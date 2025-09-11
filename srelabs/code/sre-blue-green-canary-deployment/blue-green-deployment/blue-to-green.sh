#!/usr/bin/env bash
#
# blue-to-green.sh
#
# Safely switch nginx site root between /var/www/blue and /var/www/green
# - Creates a timestamped backup of the target config before modifying
# - Validates nginx config (nginx -t) before reload
# - Restores backup on failure
#
# Usage:
#   sudo ./blue-to-green.sh            # switch to /var/www/green (default config path)
#   sudo ./blue-to-green.sh --to green
#   sudo ./blue-to-green.sh --to blue
#   sudo ./blue-to-green.sh --config /etc/nginx/sites-enabled/example.conf
#   sudo ./blue-to-green.sh --dry-run
#   sudo ./blue-to-green.sh --undo    # restore most recent backup
#
set -euo pipefail

# defaults
CONFIG_PATH="/etc/nginx/conf.d/site.conf"
TARGET_DIR_BLUE="/var/www/blue"
TARGET_DIR_GREEN="/var/www/green"
ACTION="switch"   # switch | undo | show
TO="green"        # green | blue
DRY_RUN=0

usage() {
  cat <<USAGE
Usage: sudo $0 [options]

Options:
  --config <path>    Path to nginx site config (default: ${CONFIG_PATH})
  --to <green|blue>  Target to switch to (default: green)
  --undo             Restore most recent backup of the config (undo last change)
  --dry-run          Show what would change but do not modify files or reload nginx
  -h, --help         Show this help
Examples:
  sudo $0 --to green
  sudo $0 --config /etc/nginx/sites-enabled/default --to blue
  sudo $0 --undo
  sudo $0 --dry-run --to green
USAGE
  exit 1
}

# parse args
while [[ "${#}" -gt 0 ]]; do
  case "$1" in
    --config) CONFIG_PATH="$2"; shift 2 ;;
    --to) TO="$2"; shift 2 ;;
    --undo) ACTION="undo"; shift 1 ;;
    --dry-run) DRY_RUN=1; shift 1 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

# Helper: timestamp
ts() { date +"%Y%m%dT%H%M%S"; }

# Validate config exists
if [[ "$ACTION" == "switch" ]]; then
  if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "ERROR: Nginx config not found at: $CONFIG_PATH" >&2
    exit 2
  fi
fi

# Determine target path string
if [[ "$TO" == "green" ]]; then
  TARGET_DIR="$TARGET_DIR_GREEN"
elif [[ "$TO" == "blue" ]]; then
  TARGET_DIR="$TARGET_DIR_BLUE"
else
  echo "Invalid --to value: $TO. Use 'green' or 'blue'." >&2
  exit 2
fi

# Undo operation: restore the most recent backup in same directory
if [[ "$ACTION" == "undo" ]]; then
  dirname="$(dirname "$CONFIG_PATH")"
  base="$(basename "$CONFIG_PATH")"
  # find backups matching pattern base.bak.TIMESTAMP
  backup=$(ls -1t "${dirname}/${base}.bak."* 2>/dev/null | head -n1 || true)
  if [[ -z "$backup" ]]; then
    echo "No backup found to restore for ${CONFIG_PATH}" >&2
    exit 3
  fi
  echo "Restoring backup: $backup -> $CONFIG_PATH"
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[dry-run] would restore backup"
    exit 0
  fi
  sudo cp -p "$backup" "$CONFIG_PATH"
  echo "Testing nginx configuration..."
  if sudo nginx -t; then
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    echo "Restore successful."
    exit 0
  else
    echo "Restored file failed nginx -t; keeping restored file (check manually)." >&2
    exit 4
  fi
fi

# Normal switch action
echo "Switching nginx root in: $CONFIG_PATH -> $TARGET_DIR (target $TO)"

# ensure target dir exists
if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: Target directory does not exist: $TARGET_DIR" >&2
  echo "Create it or choose the other target (blue/green)." >&2
  exit 5
fi

# create a backup
backup_ts=$(ts)
backup_path="${CONFIG_PATH}.bak.${backup_ts}"
echo "Backing up ${CONFIG_PATH} -> ${backup_path}"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] would copy $CONFIG_PATH to $backup_path"
else
  sudo cp -p "$CONFIG_PATH" "$backup_path"
fi

# Replace or add the root directive.
# Approach:
#  - if a "root <something>;" line exists, replace it
#  - else attempt to insert inside the first server { ... } block (fallback: append server root)
#
# We'll produce a temp file, then test nginx -t against it by copying into place only after validation.

tmpfile="$(mktemp /tmp/nginx-site.XXXXXX)"
sudo cp -p "$CONFIG_PATH" "$tmpfile"
sudo chown "$(id -u):$(id -g)" "$tmpfile" >/dev/null 2>&1 || true

# Use awk to replace first occurrence of "root <...>;" inside server block
# If not found, try to insert under the server { line
replaced_count=0
awk -v target="$TARGET_DIR" '
BEGIN { in_server=0; replaced=0 }
/^[[:space:]]*server[[:space:]]*\{/ { print; in_server=1; next }
{
  if (in_server && /^[[:space:]]*root[[:space:]]+/ && replaced==0) {
    sub(/root[[:space:]]+[^;]+;/, "root " target ";")
    replaced=1
    print
    next
  }
  print
}
' "$tmpfile" > "${tmpfile}.new" || true

# if replacement didn't happen (no root found), insert root under first server { occurrence
if ! grep -q "root[[:space:]]\\+${TARGET_DIR/\\//\\/}\\s*;" "${tmpfile}.new"; then
  # find line number of first server { in file
  srv_line=$(grep -n "^[[:space:]]*server[[:space:]]*{" "${tmpfile}.new" | head -n1 | cut -d: -f1 || true)
  if [[ -n "$srv_line" ]]; then
    # insert root directive after that line
    awk -v line="$srv_line" -v target="$TARGET_DIR" 'NR==line { print; print "    root " target ";"; next } {print}' "${tmpfile}.new" > "${tmpfile}.new2"
    mv "${tmpfile}.new2" "${tmpfile}.new"
  else
    # fallback: append a server block
    cat >> "${tmpfile}.new" <<EOF

server {
    listen 80;
    root ${TARGET_DIR};
    index index.html;
}
EOF
  fi
fi

# show diff (for visibility)
echo "---- Proposed config changes (diff against backup) ----"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] showing proposed changes:"
  sudo diff -u "$CONFIG_PATH" "${tmpfile}.new" || true
else
  sudo diff -u "$backup_path" "${tmpfile}.new" || true
fi

# Install the new file to place and test
if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] Would copy new config into place and test nginx -t"
  rm -f "${tmpfile}" "${tmpfile}.new" 2>/dev/null || true
  exit 0
fi

sudo cp -p "${tmpfile}.new" "$CONFIG_PATH"
rm -f "${tmpfile}" "${tmpfile}.new" 2>/dev/null || true

echo "Testing nginx configuration..."
if sudo nginx -t; then
  echo "nginx configuration OK. Reloading nginx..."
  sudo systemctl reload nginx
  echo "Switch to ${TO} successful. Backup saved as ${backup_path}."
  exit 0
else
  echo "nginx -t failed after applying new config. Restoring backup ${backup_path}..."
  sudo cp -p "$backup_path" "$CONFIG_PATH"
  echo "Restored original config. Please inspect ${backup_path} and $CONFIG_PATH"
  sudo nginx -t || true
  exit 6
fi

