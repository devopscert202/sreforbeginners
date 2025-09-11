#!/usr/bin/env bash
set -euo pipefail

# Where files will be created
ROOT="sre-blue-green-canary-deployment"
ZIP_NAME="${ROOT}.zip"

echo "Creating repository structure under ./${ROOT} ..."

# Remove pre-existing dir if user wants fresh build (comment out to keep existing)
if [ -d "$ROOT" ]; then
  echo "Removing existing $ROOT directory..."
  rm -rf "$ROOT"
fi
mkdir -p "$ROOT"

# Helper to write files
write_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$(dirname "$path")"
  printf "%s\n" "$content" > "$path"
}

#############################
# Blue-Green Deployment
#############################
BG_DIR="$ROOT/blue-green-deployment"

write_file "${BG_DIR}/nginx-config/site.conf" 'server {
    listen 80;
    root /var/www/blue;
    index index.html;
}'

write_file "${BG_DIR}/blue-version/index.html" "<!doctype html>
<html><head><meta charset='utf-8'><title>Blue</title></head>
<body><h1 style='background-color:blue;color:white;text-align:center;'>Blue Version - Initial Deployment</h1></body></html>"

write_file "${BG_DIR}/green-version/index.html" "<!doctype html>
<html><head><meta charset='utf-8'><title>Green</title></head>
<body><h1 style='background-color:green;color:white;text-align:center;'>Green Version - Upgraded Deployment</h1></body></html>"

write_file "${BG_DIR}/setup.sh" '#!/bin/bash
set -euo pipefail
echo "Running Blue-Green setup (assumes Amazon Linux / yum). Adjust package manager if needed."

# Update packages and install nginx & python3
if command -v yum >/dev/null 2>&1; then
  sudo yum update -y
  sudo yum install -y nginx python3
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y nginx python3
else
  echo "No known package manager (yum/apt). Install nginx & python3 manually." >&2
fi

# Ensure nginx is running
sudo systemctl enable --now nginx || true

# Create blue/green content
sudo mkdir -p /var/www/blue /var/www/green
echo "<!doctype html><html><body><h1 style=\"background-color:blue;color:white;text-align:center;\">Blue Version - Initial Deployment</h1></body></html>" | sudo tee /var/www/blue/index.html >/dev/null
echo "<!doctype html><html><body><h1 style=\"background-color:green;color:white;text-align:center;\">Green Version - Upgraded Deployment</h1></body></html>" | sudo tee /var/www/green/index.html >/dev/null

# Write Nginx site configuration to point to blue by default
sudo tee /etc/nginx/conf.d/site.conf > /dev/null <<'NGINX_CONF'
server {
    listen 80;
    root /var/www/blue;
    index index.html;
}
NGINX_CONF

# Test and reload nginx
sudo nginx -t
sudo systemctl reload nginx

echo "Blue-Green setup complete. Visit the server IP to confirm Blue content."
'

# Make setup script executable
chmod +x "${BG_DIR}/setup.sh"

write_file "${BG_DIR}/README.md" '# Blue-Green Deployment

## Objective
Implement Blue-Green deployment with nginx. Blue is active initially; switching the root in nginx config to /var/www/green and reloading nginx switches to Green.

## Quick steps
1. SSH into EC2 instance.
2. Copy the contents of this folder to the EC2 host (or git clone).
3. Run: sudo ./setup.sh
4. Verify blue page via: curl http://localhost or browser.
5. To switch to green:
   - Edit /etc/nginx/conf.d/site.conf to `root /var/www/green;`
   - sudo nginx -t && sudo systemctl reload nginx
6. Verify green page.

'

#############################
# Canary Deployment
#############################
CAN_DIR="$ROOT/canary-deployment"

write_file "${CAN_DIR}/nginx-config/nginx.conf" 'user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '\''$remote_addr - $remote_user [$time_local] "$request" '\''
                      '\''$status $body_bytes_sent "$http_referer" '\''
                      '"$http_user_agent" "$http_x_forwarded_for"'\'' ;

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 4096;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream app_servers {
        server 127.0.0.1:8081 weight=8;   # Blue gets 80%
        server 127.0.0.1:8082 weight=2;   # Green gets 20%
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}'

write_file "${CAN_DIR}/blue-version/index.html" "<!doctype html>
<html><head><meta charset='utf-8'><title>Blue Canary</title></head>
<body><h1 style='background-color:blue;color:white;text-align:center;'>Blue Version Canary Test</h1></body></html>"

write_file "${CAN_DIR}/green-version/index.html" "<!doctype html>
<html><head><meta charset='utf-8'><title>Green Canary</title></head>
<body><h1 style='background-color:green;color:white;text-align:center;'>Green Version Canary Test</h1></body></html>"

write_file "${CAN_DIR}/setup.sh" '#!/bin/bash
set -euo pipefail
echo "Running Canary setup (assumes Amazon Linux / yum). Adjust package manager if needed."

if command -v yum >/dev/null 2>&1; then
  sudo yum update -y
  sudo yum install -y nginx python3
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y nginx python3
else
  echo "No known package manager (yum/apt). Install nginx & python3 manually." >&2
fi

sudo systemctl enable --now nginx || true

# Prepare content and start two simple python servers for blue and green
sudo mkdir -p /var/www/blue /var/www/green
echo "<!doctype html><html><body><h1 style=\"background-color:blue;color:white;text-align:center;\">Blue Version Canary Test</h1></body></html>" | sudo tee /var/www/blue/index.html >/dev/null
echo "<!doctype html><html><body><h1 style=\"background-color:green;color:white;text-align:center;\">Green Version Canary Test</h1></body></html>" | sudo tee /var/www/green/index.html >/dev/null

# Start simple HTTP servers on ports 8081 and 8082 (background)
# Use nohup so they survive after shell exits in training VMs
nohup python3 -m http.server 8081 --directory /var/www/blue >/tmp/blue.log 2>&1 &
nohup python3 -m http.server 8082 --directory /var/www/green >/tmp/green.log 2>&1 &

# Write nginx config
sudo tee /etc/nginx/nginx.conf > /dev/null <<'"NGINX_CONF"'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '\''$remote_addr - $remote_user [$time_local] "$request" '\'' 
                      '\''$status $body_bytes_sent "$http_referer" '\''
                      '"$http_user_agent" "$http_x_forwarded_for"'\'' ;

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 4096;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    upstream app_servers {
        server 127.0.0.1:8081 weight=8;
        server 127.0.0.1:8082 weight=2;
    }

    server {
        listen 80;
        server_name _;

        location / {
            proxy_pass http://app_servers;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }
}
NGINX_CONF

sudo nginx -t
sudo systemctl reload nginx

echo "Canary setup complete. Hit http://localhost repeatedly to observe distribution."
'

chmod +x "${CAN_DIR}/setup.sh"

write_file "${CAN_DIR}/README.md" '# Canary Deployment

## Objective
Run Blue and Green versions on two local ports and use nginx upstream weights to send ~80% traffic to blue, ~20% to green.

## Quick steps
1. SSH into EC2 (or VM).
2. Copy this folder or git clone repo.
3. Run: sudo ./setup.sh
4. Test with:
   for i in {1..20}; do curl -s http://localhost | grep h1; done

Adjust upstream weights in /etc/nginx/nginx.conf to change traffic split.
'

#############################
# Root README
#############################
write_file "${ROOT}/README.md" '# SRE Blue-Green and Canary Deployment

This repository contains two sample setups:

- blue-green-deployment: nginx root points at /var/www/blue (switch to /var/www/green for green)
- canary-deployment: nginx upstream load balancing between python servers on 8081 (blue) and 8082 (green)

Each deployment folder has setup.sh (runnable on Amazon Linux / Debian with minor tweaks) and README.md with quick instructions.
'

# Make sure scripts are executable
chmod +x "${BG_DIR}/setup.sh" "${CAN_DIR}/setup.sh"

# Create zip
if [ -f "$ZIP_NAME" ]; then
  rm -f "$ZIP_NAME"
fi

# Use zip utility if available for deterministic zip; otherwise fallback to python zip
if command -v zip >/dev/null 2>&1; then
  (cd "$(dirname "$ROOT")" || exit 1; zip -r "../${ZIP_NAME}" "$(basename "$ROOT")") 
else
  # fallback to python's shutil.make_archive
  python3 - <<PY
import shutil
shutil.make_archive("${ROOT}", "zip", "${ROOT}")
PY
  # move created zip to current directory if needed (shutil makes ./sre-blue-green-canary-deployment.zip)
fi

# Validation output
echo
echo "Created ${ZIP_NAME} in the current directory. Contents:"
if command -v unzip >/dev/null 2>&1; then
  unzip -l "${ZIP_NAME}"
else
  # list entries using python
  python3 - <<PY
import zipfile
zf = zipfile.ZipFile("${ZIP_NAME}")
for info in zf.infolist():
    print(info.filename)
PY
fi

echo
echo "Local folder structure created at ./${ROOT}"
echo "To upload to GitHub:"
echo "  - Option A (gh CLI installed):"
echo "      gh repo create <your-org-or-username>/${ROOT} --public --source=. --remote=origin --push"
echo "  - Option B (manual):"
echo "      cd ${ROOT}; git init; git add .; git commit -m \"Initial\"; create empty repo on GitHub; git remote add origin <URL>; git push -u origin master"
echo
echo "If you run into permission issues when executing setup.sh on the VM, use sudo to run it."

exit 0

