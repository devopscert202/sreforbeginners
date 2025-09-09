# 🧪 Lab 12: Implementing Chaos Engineering with Pumba  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

**Chaos Engineering** is the practice of deliberately injecting failures into a system to test its resilience and recovery. By introducing random failures, teams validate whether applications can withstand outages without breaching SLOs.  

In this lab, you will deploy a Flask application in Docker and use **Pumba** (a chaos engineering tool) to kill containers at random intervals, validating resilience under chaos.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Deploy a Flask app in Docker.  
- Add Pumba to simulate container crashes.  
- Observe resilience of the application when chaos is injected.  

---

## 📋 Prerequisites  
- EC2 instance (Amazon Linux 2) with Docker & Docker Compose installed.  
- Security group inbound rules: open port **5001** for Flask app.  
- Basic knowledge of Linux, Docker, Python.  

---

## 🔨 Steps  

### Step 1: Install Docker & Docker Compose  
```bash
sudo yum install -y docker
sudo service docker start
sudo usermod -aG docker ec2-user
docker --version

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
````

---

### Step 2: Create Flask App

```bash
mkdir ~/chaos-lab && cd ~/chaos-lab
mkdir flask_app
cd flask_app
nano app.py
```

Paste:

```python
from flask import Flask
import socket, datetime, random, string

app = Flask(__name__)
start_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
container_id = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))

@app.route('/')
def hello():
    return f"""
    Hello from Flask!<br>
    Hostname: {socket.gethostname()}<br>
    Container start time: {start_time}<br>
    Container ID: {container_id}
    """

@app.route('/health')
def health():
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Save & exit.

Create `requirements.txt`:

```bash
nano requirements.txt
```

Content:

```
flask
```

Create `Dockerfile`:

```bash
nano Dockerfile
```

Content:

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]
```

---

### Step 3: Create Docker Compose with Pumba

```bash
cd ~/chaos-lab
nano docker-compose.yml
```

Paste:

```yaml
version: "3.8"

services:
  flask-app:
    build: ./flask_app
    container_name: flask-app-chaos
    ports:
      - "5001:5000"
    restart: always

  pumba:
    image: gaiaadm/pumba:latest
    container_name: pumba
    command: ["--interval", "30s", "kill", "--signal", "SIGTERM", "re2:^flask-app-chaos(_\\d+)?$"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
```

---

### Step 4: Build & Launch Containers

```bash
docker-compose up --build -d
docker ps
```

---

### Step 5: Access Application & Monitor Chaos

Open:

```
http://<EC2_PUBLIC_IP>:5001/
```

Observe logs:

```bash
docker events --filter container=flask-app-chaos
```

Check Flask logs:

```bash
docker logs -f flask-app-chaos
```

✅ Expected: Flask container restarts periodically due to Pumba chaos injection.

---

## 🧾 Testing & Validation

1. Verify app works initially:

   ```bash
   curl http://localhost:5001/
   ```

   ✅ Expected: “Hello from Flask” message with container details.

2. Observe chaos injection every \~30s:

   ```bash
   docker logs -f flask-app-chaos
   ```

   ✅ Expected: Container stops and restarts automatically.

3. Refresh browser repeatedly.
   ✅ Expected: Container ID changes after restarts, showing resilience.

---

## 📌 Further Learning (SRE Context)

* Chaos Engineering validates **resilience before failures happen in production**.
* Pumba simulates random container crashes. In real-world SRE:

  * Tools like **Chaos Mesh** or **Gremlin** are used for distributed systems.
  * Chaos tests include latency injection, network failures, CPU/memory hogs.
* Resilience tests must be tied to **SLIs/SLOs**:

  * Does chaos cause SLO violations?
  * Is error budget impacted?

---

## ✅ Lab Completion

You have successfully:

* Deployed a Flask app with Docker.
* Used Pumba to inject chaos.
* Observed application resilience under container restarts.

This lab introduces **chaos engineering**, a proactive SRE practice for building reliable systems.

👉 Would you like me to generate **Lab 13 (`lab13.md`: Multi-User Load Testing with Chaos)** right away, or pause so you can review this `lab12.md` format first?
```
