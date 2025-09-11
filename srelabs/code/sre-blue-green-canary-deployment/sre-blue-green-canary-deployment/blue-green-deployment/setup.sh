#!/bin/bash
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
sudo tee /etc/nginx/conf.d/site.conf > /dev/null <<NGINX_CONF
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

