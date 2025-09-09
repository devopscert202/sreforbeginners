# 🧪 Lab 13: Performing Multi-User Load Testing with Chaos  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

Load testing simulates multiple users interacting with a service to measure its **performance, scalability, and resilience**. Combined with **chaos engineering**, we can see how the system behaves under stress and random failures.  

In this lab, you will use **Locust** (a Python-based load testing tool) to generate traffic against a Flask application. You will then observe how chaos injection (via Pumba) impacts performance under load.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Deploy a sample Flask application in Docker.  
- Install and configure Locust for load testing.  
- Run multi-user load tests.  
- Combine load tests with chaos injection to assess resilience.  

---

## 📋 Prerequisites  
- EC2 instance (Amazon Linux 2) with Docker & Docker Compose.  
- Flask application deployed (from **Lab 12**).  
- Locust installed on EC2 or local machine.  
- Security group inbound rules: allow ports **5001 (Flask)** and **8089 (Locust web UI)**.  

---

## 🔨 Steps  

### Step 1: Install Locust  
```bash
pip3 install locust
````

Verify installation:

```bash
locust --version
```

---

### Step 2: Create Locust Test Script

```bash
mkdir ~/load-test && cd ~/load-test
nano locustfile.py
```

Paste:

```python
from locust import HttpUser, task, between

class WebsiteUser(HttpUser):
    wait_time = between(1, 5)

    @task(3)
    def home(self):
        self.client.get("/")

    @task(1)
    def health(self):
        self.client.get("/health")
```

Save & exit.

---

### Step 3: Run Locust

```bash
locust -f locustfile.py --host=http://<EC2_PUBLIC_IP>:5001
```

Access Locust UI in browser:

```
http://<EC2_PUBLIC_IP>:8089
```

---

### Step 4: Configure Load Test

In the Locust web UI:

* Number of users: **100** (simulated).
* Spawn rate: **10 users/sec**.
* Host: `http://<EC2_PUBLIC_IP>:5001`.

Click **Start Swarming**.

✅ Expected: Traffic begins hitting the Flask app.

---

### Step 5: Observe Metrics

Locust displays:

* Requests per second (RPS).
* Response times (avg, p95).
* Failures (if app becomes unresponsive).

---

### Step 6: Combine with Chaos (Pumba)

Ensure Pumba is running from **Lab 12**:

```bash
docker ps | grep pumba
```

If not, start chaos again:

```bash
cd ~/chaos-lab
docker-compose up -d
```

Observe:

* As Pumba kills and restarts the Flask container, some requests in Locust may fail.
* Latency may spike during container restarts.

---

## 🧾 Testing & Validation

1. **Check Locust Installation**

   ```bash
   locust --version
   ```

   ✅ Expected: Locust version output.

2. **Basic Load Test (No Chaos)**

   * Run Locust → 100 users.
   * ✅ Expected: Flask app handles requests consistently, low failure rate.

3. **Load Test with Chaos Enabled**

   * Pumba restarts container.
   * ✅ Expected: Some failed requests & latency spikes during chaos events.

4. **Health Endpoint Check**

   ```bash
   curl http://<EC2_PUBLIC_IP>:5001/health
   ```

   ✅ Expected: “OK”.

---

## 📌 Further Learning (SRE Context)

* **Load Testing** validates whether the system meets **SLOs** under expected or peak load.
* **Chaos + Load Testing** reveals resilience gaps:

  * Does the system recover gracefully?
  * How does latency/error rate impact SLI measurements?
* In production:

  * Use distributed load testing (k6, JMeter, Locust clusters).
  * Automate chaos scenarios tied to **error budgets**.

---

## ✅ Lab Completion

You have successfully:

* Installed and configured Locust.
* Ran multi-user load tests against a Flask app.
* Observed system behavior under chaos injection.

This lab demonstrates **performance + resilience testing** — key SRE practices for reliability validation.

