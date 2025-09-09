# 🧪 Lab 04: Setting up Prometheus and Grafana for Monitoring  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  
Monitoring is a key SRE responsibility, and **Prometheus** (metrics collection) with **Grafana** (visualization) are widely used open-source tools to achieve this.  

In this lab, you will deploy Prometheus and Grafana using Docker Compose, configure Prometheus to scrape system metrics, and visualize them in Grafana.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Deploy Prometheus and Grafana with Docker Compose.  
- Configure Prometheus to collect metrics.  
- Access Prometheus UI and Grafana dashboards.  

---

## 📋 Prerequisites  
- AWS EC2 instance (Amazon Linux 2) created in **Lab 01**.  
- Docker and Docker Compose installed.  
- Security group inbound rules: open ports **9090 (Prometheus)** and **3000 (Grafana)**.  

---

## 🔨 Steps  

### Step 1: Update Packages and Install Docker  
Run the following commands in your EC2 terminal:  
```bash
sudo yum update -y
sudo yum install -y docker
````

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Allow `ec2-user` to use Docker without `sudo`:

```bash
sudo usermod -aG docker ec2-user
newgrp docker
```

Verify Docker installation:

```bash
docker --version
```

---

### Step 2: Install Docker Compose

```bash
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

---

### Step 3: Create Working Directory

```bash
mkdir ~/prometheus-grafana
cd ~/prometheus-grafana
```

---

### Step 4: Create Prometheus Configuration File

```bash
nano prometheus.yml
```

Paste the following content:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
```

Save and exit (`CTRL+O`, Enter, `CTRL+X`).

---

### Step 5: Create Docker Compose File

```bash
nano docker-compose.yml
```

Paste the following:

```yaml
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

Save and exit.

---

### Step 6: Start Prometheus and Grafana

```bash
docker-compose up -d
```

Check running containers:

```bash
docker ps
```

---

### Step 7: Access Prometheus and Grafana

* Prometheus: `http://<EC2_PUBLIC_IP>:9090`
* Grafana: `http://<EC2_PUBLIC_IP>:3000`

Default Grafana login:

* **Username:** admin
* **Password:** admin

Change password when prompted.

---

### Step 8: Configure Grafana to Use Prometheus

1. In Grafana, go to **Configuration → Data Sources**.
2. Add Prometheus as a new data source:

   * URL: `http://prometheus:9090` (inside Docker network)
   * Or: `http://<EC2_PUBLIC_IP>:9090` (from external browser).
3. Save & Test → should succeed.

---

### Step 9: Create a Grafana Dashboard

1. Click **+ Create → Dashboard**.
2. Add a panel with a simple PromQL query:

   ```promql
   up
   ```

   This shows the health of monitored services.
3. Save the dashboard.

---

## 🧾 Testing & Validation

1. Verify Prometheus targets:

   * Open `http://<EC2_PUBLIC_IP>:9090/targets`
   * ✅ Expected: `prometheus` target is UP.

2. Verify Grafana:

   * Log in at `http://<EC2_PUBLIC_IP>:3000`.
   * Add Prometheus as a data source → ✅ Test succeeds.

3. Verify Metrics:

   * Create a panel with PromQL query:

     ```promql
     rate(prometheus_http_requests_total[1m])
     ```
   * ✅ Expected: Graph of Prometheus HTTP request rates.

---

## 📌 Further Learning (SRE Context)

* **Golden Signals of Monitoring** (SRE must monitor at least these):

  * Latency
  * Traffic
  * Errors
  * Saturation
* Prometheus + Grafana are widely used to monitor these signals.
* These metrics later feed into **alerting and incident management** (Labs 05 & 06).

---

## ✅ Lab Completion

You have successfully:

* Installed Docker and Docker Compose.
* Deployed Prometheus and Grafana.
* Configured Prometheus to collect metrics.
* Connected Grafana to Prometheus and created a dashboard.

You are now ready to explore **incident management** in the next lab.

```

👉 Shall I move on to **Lab 05 (`lab05.md`: Implementing Incident Management with Prometheus)** next, using this same detailed and clarified approach?
```
