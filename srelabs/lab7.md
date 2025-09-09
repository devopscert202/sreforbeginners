# 🧪 Lab 07: Implementing SRE with Blue-Green and Canary Deployment  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

One of the SRE principles is to minimize the **risk of change** when deploying new versions of a service. Two common strategies are:  

- **Blue-Green Deployment:** Maintain two environments (Blue = current production, Green = new version). Switch traffic to Green only after validation.  
- **Canary Deployment:** Gradually route a small percentage of traffic to the new version (canary) before a full rollout.  

In this lab, you will implement both deployment strategies using **Nginx and Docker** on an EC2 instance.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Deploy two versions of a web application (Blue & Green).  
- Use Nginx as a reverse proxy to switch traffic.  
- Perform a Canary rollout with weighted traffic routing.  
- Validate deployment behavior.  

---

## 📋 Prerequisites  
- EC2 instance with Docker and Docker Compose installed.  
- Basic knowledge of Dockerfile and Nginx configuration.  
- Security group inbound rules: open port **80** (HTTP).  

---

## 🔨 Steps  

### Step 1: Prepare Working Directory  
```bash
mkdir ~/blue-green-canary
cd ~/blue-green-canary
````

---

### Step 2: Create Two Versions of a Simple Web App

#### Blue Version (current production)

```bash
mkdir app-blue
cd app-blue
nano index.html
```

Paste content:

```html
<!DOCTYPE html>
<html>
  <head><title>Blue Version</title></head>
  <body><h1>Welcome to the Blue Version!</h1></body>
</html>
```

Create Dockerfile:

```bash
nano Dockerfile
```

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

Build the image:

```bash
docker build -t app-blue .
```

---

#### Green Version (new release)

```bash
cd ~/blue-green-canary
mkdir app-green
cd app-green
nano index.html
```

Paste content:

```html
<!DOCTYPE html>
<html>
  <head><title>Green Version</title></head>
  <body><h1>Welcome to the Green Version!</h1></body>
</html>
```

Create Dockerfile:

```bash
nano Dockerfile
```

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

Build the image:

```bash
docker build -t app-green .
```

---

### Step 3: Create Nginx Reverse Proxy for Blue-Green Deployment

Go back to working directory:

```bash
cd ~/blue-green-canary
nano nginx.conf
```

Paste the following config (start with Blue as default):

```nginx
events {}

http {
  upstream backend {
    server app-blue:80;
    # server app-green:80;  # Uncomment this to switch to Green
  }

  server {
    listen 80;
    location / {
      proxy_pass http://backend;
    }
  }
}
```

---

### Step 4: Create Docker Compose File

```bash
nano docker-compose.yml
```

Paste content:

```yaml
version: "3.8"

services:
  app-blue:
    image: app-blue
    container_name: app-blue

  app-green:
    image: app-green
    container_name: app-green

  nginx:
    image: nginx:alpine
    container_name: nginx-proxy
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app-blue
      - app-green
```

---

### Step 5: Launch Blue-Green Environment

```bash
docker-compose up -d
```

Check containers:

```bash
docker ps
```

---

### Step 6: Validate Blue Deployment

Open in browser:

```
http://<EC2_PUBLIC_IP>
```

✅ Expected: “Welcome to the Blue Version!”

---

### Step 7: Switch to Green Deployment

Edit `nginx.conf`:

```bash
nano nginx.conf
```

Change upstream block:

```nginx
upstream backend {
    # server app-blue:80;
    server app-green:80;
}
```

Reload containers:

```bash
docker-compose down
docker-compose up -d
```

✅ Expected: Visiting `http://<EC2_PUBLIC_IP>` now shows **Green Version**.

---

### Step 8: Implement Canary Deployment

Update `nginx.conf`:

```bash
nano nginx.conf
```

Set weighted traffic distribution:

```nginx
upstream backend {
    server app-blue:80 weight=3;
    server app-green:80 weight=1;
}

server {
    listen 80;
    location / {
      proxy_pass http://backend;
    }
}
```

Reload Nginx:

```bash
docker-compose restart nginx
```

✅ Expected:

* \~75% of requests → Blue version.
* \~25% of requests → Green version.

Test with multiple curl requests:

```bash
for i in {1..10}; do curl -s http://<EC2_PUBLIC_IP> | grep "<h1>"; done
```

You should see a mix of “Blue” and “Green” responses.

---

## 🧾 Testing & Validation

1. **Blue Deployment Check:**

   ```bash
   curl -s http://<EC2_PUBLIC_IP> | grep "<h1>"
   ```

   ✅ Expect: *Blue Version*

2. **Green Deployment Check (after switch):**

   ```bash
   curl -s http://<EC2_PUBLIC_IP> | grep "<h1>"
   ```

   ✅ Expect: *Green Version*

3. **Canary Check:**

   ```bash
   for i in {1..10}; do curl -s http://<EC2_PUBLIC_IP> | grep "<h1>"; done
   ```

   ✅ Expect: Majority Blue, some Green responses.

---

## 📌 Further Learning (SRE Context)

* **Blue-Green Deployment** ensures safe rollback — switch traffic back to Blue if Green fails.
* **Canary Deployment** minimizes blast radius by exposing only a fraction of users to new code.
* These strategies **reduce risk of incidents during releases**, a core SRE concern.
* In production:

  * Canary rollout is often integrated with **monitoring (Prometheus, Grafana)**.
  * Automated rollback triggers if error rate / latency exceed SLOs.

---

## ✅ Lab Completion

You have successfully:

* Built Blue and Green app versions.
* Configured Nginx reverse proxy for Blue-Green switching.
* Implemented Canary deployment with weighted traffic.
* Validated outputs using curl and browser tests.

This lab demonstrates how SREs enable **safe, reliable release engineering practices**.

👉 Shall I move ahead and process **Lab 08 (`lab08.md`: Automating SRE with Ansible and HTTPS Nginx)** next in the same style?
```
