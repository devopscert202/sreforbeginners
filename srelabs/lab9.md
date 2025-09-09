# 🧪 Lab 09: Monitoring EC2 Instance and Alerting Strategy with Prometheus Node Exporter and Alertmanager  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

SREs must monitor **system-level metrics** (CPU, memory, disk, network) and create alerts when thresholds are breached. **Node Exporter** is the Prometheus exporter for machine metrics. **Alertmanager** manages alert delivery (e.g., email, Slack, PagerDuty).  

In this lab, you will:  
- Deploy **Node Exporter** on your EC2 instance.  
- Configure **Prometheus** to scrape Node Exporter metrics.  
- Set up **Alertmanager** for basic alerting strategy.  
- Test an alert by simulating a failure condition.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Run Node Exporter to expose system metrics.  
- Configure Prometheus to scrape Node Exporter.  
- Configure Alertmanager and connect it to Prometheus.  
- Validate alerts are triggered when conditions are met.  

---

## 📋 Prerequisites  
- EC2 instance (Amazon Linux 2) with Docker & Docker Compose installed.  
- Prometheus & Grafana deployed (from **Lab 04**).  
- Security group inbound rules: open ports **9100 (Node Exporter)** and **9093 (Alertmanager)**.  

---

## 🔨 Steps  

### Step 1: Start Node Exporter in Docker  
Navigate to your monitoring directory:  
```bash
cd ~/prometheus-grafana
````

Run Node Exporter container:

```bash
docker run -d --name=node-exporter \
  -p 9100:9100 \
  prom/node-exporter
```

Verify container:

```bash
docker ps | grep node-exporter
```

✅ Expected: Node Exporter container running on port 9100.

---

### Step 2: Configure Prometheus to Scrape Node Exporter

Edit Prometheus config:

```bash
nano prometheus.yml
```

Add a job for Node Exporter:

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
```

Save and exit.

---

### Step 3: Restart Prometheus

```bash
cd ~/prometheus-grafana
docker-compose down
docker-compose up -d
```

Check logs for errors:

```bash
docker logs prometheus
```

---

### Step 4: Verify Node Exporter Metrics

Open in browser:

```
http://<EC2_PUBLIC_IP>:9100/metrics
```

✅ Expected: Raw metrics output (CPU, memory, disk, etc.).

Check in Prometheus Targets page:

```
http://<EC2_PUBLIC_IP>:9090/targets
```

✅ Expected: `node_exporter` target UP.

---

### Step 5: Set Up Alertmanager with Docker

Create an Alertmanager config file:

```bash
nano alertmanager.yml
```

Paste:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: "default"

receivers:
  - name: "default"
    # Example email config (not active until SMTP configured)
    # email_configs:
    #   - to: "your-email@example.com"
```

Save and exit.

Run Alertmanager container:

```bash
docker run -d --name alertmanager \
  -p 9093:9093 \
  -v $(pwd)/alertmanager.yml:/etc/alertmanager/alertmanager.yml \
  prom/alertmanager
```

Verify:

```bash
docker ps | grep alertmanager
```

---

### Step 6: Configure Prometheus to Use Alertmanager

Edit Prometheus config again:

```bash
nano prometheus.yml
```

Add Alertmanager section at the bottom:

```yaml
alerting:
  alertmanagers:
    - static_configs:
        - targets: ["localhost:9093"]
```

---

### Step 7: Create Alerting Rule

Create new file:

```bash
nano alert-rules.yml
```

Paste:

```yaml
groups:
  - name: node_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage above 80% for more than 1 minute."
```

Save and exit.

Update `prometheus.yml` to load rules:

```yaml
rule_files:
  - "alert-rules.yml"
```

---

### Step 8: Restart Prometheus with Alert Rules

```bash
docker-compose down
docker-compose up -d
```

Check that rules loaded:

```
http://<EC2_PUBLIC_IP>:9090/rules
```

✅ Expected: `HighCPUUsage` alert listed.

---

### Step 9: Trigger and Observe Alert

Simulate CPU load:

```bash
sudo yum install -y stress
stress --cpu 2 --timeout 120
```

Check Alerts page:

```
http://<EC2_PUBLIC_IP>:9090/alerts
```

✅ Expected: `HighCPUUsage` alert becomes **firing** after \~1 minute.

Open Alertmanager UI:

```
http://<EC2_PUBLIC_IP>:9093
```

✅ Expected: Alert visible in Alertmanager dashboard.

---

## 🧾 Testing & Validation

1. **Node Exporter Check:**

   ```bash
   curl http://localhost:9100/metrics | head -n 5
   ```

   ✅ Expected: Prometheus metrics format output.

2. **Prometheus Target Check:**

   ```bash
   curl http://localhost:9090/api/v1/targets | jq
   ```

   ✅ Expected: Node Exporter target `UP`.

3. **Alert Rule Check:**

   ```bash
   curl http://localhost:9090/api/v1/rules | jq
   ```

   ✅ Expected: `HighCPUUsage` listed.

4. **Simulated Alert:**
   Run `stress` and confirm alert appears in Prometheus → Alerts page.

---

## 📌 Further Learning (SRE Context)

* **Node Exporter** provides host-level visibility (Golden Signal: Saturation).
* **Prometheus + Alertmanager** implement automated incident detection and alert routing.
* In real-world SRE practice:

  * Alerts are routed to Slack, PagerDuty, or OpsGenie.
  * Alerts should be tied to **SLO violations**, not raw metrics (reduces alert fatigue).
  * Incident response automation can trigger remediation (restart service, autoscale).

---

## ✅ Lab Completion

You have successfully:

* Deployed Node Exporter on EC2.
* Configured Prometheus to scrape system metrics.
* Set up Alertmanager with basic config.
* Created an alert rule for high CPU usage and validated it.

This lab demonstrates **monitoring + alerting integration** — key to SRE incident management practices.

