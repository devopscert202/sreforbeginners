

### Documentation of Blue/green deployment and Canary deployment

### Folder Structure and Code for GitHub Repository

We will create a **folder structure** that divides the code into two separate deployment strategies: **Blue-Green Deployment** and **Canary Deployment**. Both will be kept in different directories, and I'll include a **README.md** file with clear instructions.

---

### **Suggested Folder Structure**

```
sre-blue-green-canary-deployment/
├── blue-green-deployment/
│   ├── nginx-config/
│   │   └── site.conf
│   ├── blue-version/
│   │   └── index.html
│   ├── green-version/
│   │   └── index.html
│   ├── setup.sh
│   └── README.md
│
├── canary-deployment/
│   ├── nginx-config/
│   │   └── nginx.conf
│   ├── blue-version/
│   │   └── index.html
│   ├── green-version/
│   │   └── index.html
│   ├── setup.sh
│   └── README.md
│
└── README.md
```

---

### **1. Blue-Green Deployment Setup**

#### **1.1 nginx-config/site.conf**

This configuration file defines the blue version as the default active deployment for Nginx.

```nginx
server {
    listen 80;
    root /var/www/blue;
    index index.html;
}
```

#### **1.2 blue-version/index.html**

The initial version of the service, named **Blue Version**.

```html
<h1 style='background-color:blue;color:white;text-align:center;'>Blue Version - Initial Deployment</h1>
```

#### **1.3 green-version/index.html**

The upgraded version of the service, named **Green Version**.

```html
<h1 style='background-color:green;color:white;text-align:center;'>Green Version - Upgraded Deployment</h1>
```

#### **1.4 setup.sh**

Shell script to install Nginx, create blue/green versions, and configure Nginx for Blue-Green deployment.

```bash
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
```

#### **1.5 README.md**

Instructions for setting up the Blue-Green deployment on AWS EC2.

```markdown
# Blue-Green Deployment

## Objective:
To implement blue-green deployment ensuring zero downtime during application upgrades. This setup will start with the **Blue** version and allow seamless switch to the **Green** version.

## Steps:
1. Launch an EC2 instance and SSH into it.
2. Run the setup script to install Nginx, create blue/green versions, and configure Nginx.
3. Verify the blue version is live by visiting the EC2 public IP.
4. Switch to the green version by modifying Nginx configuration and reload.

### Test the Deployment:
- Once the green version is active, refresh your browser to confirm the upgrade.

For more detailed instructions, refer to the lab steps in the provided document.
```

---

### **2. Canary Deployment Setup**

#### **2.1 nginx-config/nginx.conf**

Nginx configuration with weighted load balancing for Canary deployment.

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 4096;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Canary Weighted Load Balancing
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
}
```

#### **2.2 blue-version/index.html**

This file is used for the Blue version in Canary.

```html
<h1 style='background-color:blue;color:white;text-align:center;'>Blue Version Canary Test</h1>
```

#### **2.3 green-version/index.html**

This file is used for the Green version in Canary.

```html
<h1 style='background-color:green;color:white;text-align:center;'>Green Version Canary Test</h1>
```

#### **2.4 setup.sh**

Shell script for setting up Canary deployment by starting Python servers for the Blue and Green versions on different ports (8081 and 8082).

```bash
#!/bin/bash

# Install Nginx and Python3
sudo yum update -y
sudo yum install -y nginx python3

# Start Nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Blue version setup
sudo mkdir -p /var/www/blue
echo "<h1 style='background-color:blue;color:white;text-align:center;'>Blue Version Canary Test</h1>" | sudo tee /var/www/blue/index.html
nohup python3 -m http.server 8081 --directory /var/www/blue &

# Green version setup
sudo mkdir -p /var/www/green
echo "<h1 style='background-color:green;color:white;text-align:center;'>Green Version Canary Test</h1>" | sudo tee /var/www/green/index.html
nohup python3 -m http.server 8082 --directory /var/www/green &

# Update Nginx config for Canary deployment
sudo tee /etc/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;

    types_hash_max_size 4096;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Canary Weighted Load Balancing
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
}
EOF

# Test and reload Nginx configuration
sudo nginx -t
sudo systemctl reload nginx
```

#### **2.5 README.md**

Instructions for setting up Canary deployment on AWS EC2.

````markdown
# Canary Deployment

## Objective:
To implement a canary deployment strategy where traffic is split between the Blue and Green versions of the service.

## Steps:
1. Launch an EC2 instance and SSH into it.
2. Run the setup script to install Nginx, create Blue/Green versions, and configure Nginx for Canary deployment.
3. Verify Blue and Green versions are running on ports 8081 and 8082.
4. Observe traffic split using weighted load balancing (80% Blue, 20% Green).

### Test the Deployment:
- Run multiple `curl` requests to check traffic distribution:
  ```bash
  for i in {1..20}; do curl -s http://localhost | grep h1; done
````

Expect around 80% Blue and 20% Green responses.

For more detailed instructions, refer to the lab steps in the provided document.

````

---

### **Top-Level README.md**  
Instructions for the overall project repository.

```markdown
# SRE Blue-Green and Canary Deployment

This repository contains code and instructions for implementing Blue-Green and Canary deployment strategies in AWS using Nginx. These strategies ensure **zero downtime** during upgrades and validate seamless version switching.

## Folder Structure:
- `blue-green-deployment/`: Setup for blue-green deployment (two environments: Blue and Green).
- `canary-deployment/`: Setup for canary deployment, which splits traffic between Blue and Green versions.

## Instructions:
1. Choose either Blue-Green or Canary deployment folder.
2. Follow the provided `README.md` instructions for setup and testing.
3. Use the `setup.sh` script to configure your environment and test the deployment strategies.

## Requirements:
- AWS EC2 instance (Amazon Linux 2) with Nginx installed.
- Basic knowledge of Linux commands and Nginx configuration.

For detailed setup and testing instructions, check the respective folder’s `README.md` files.
````

Let me know if you need help uploading this or have any more questions!
