#!/bin/bash

# Install Nginx and Python3
sudo yum update -y
sudo yum install -y nginx python3

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Create blue version
sudo mkdir -p /var/www/blue
echo "<h1 style='background-color:blue;color:white;text-align:center;'>Blue Version - Initial Deployment</h1>" | sudo tee /var/www/blue/index.html

# Create green version
sudo mkdir -p /var/www/green
echo "<h1 style='background-color:green;color:white;text-align:center;'>Green Version - Upgraded Deployment</h1>" | sudo tee /var/www/green/index.html

# Nginx config to start with blue
sudo tee /etc/nginx/conf.d/site.conf <<EOF
server {
    listen 80;
    root /var/www/blue;
    index index.html;
}
EOF

# Test and reload Nginx configuration
sudo nginx -t
sudo systemctl reload nginx

