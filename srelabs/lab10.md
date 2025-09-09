# 🧪 Lab 10: Setting Up System Monitoring, Incident Alerts and Response with Prometheus and Alertmanager  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

SREs need to **detect, alert, and respond** to system incidents quickly. **Prometheus** collects metrics, **Alertmanager** routes alerts, and automated scripts can perform **self-healing responses**.  

In this lab, you will:  
- Configure Prometheus to monitor system metrics.  
- Create alert rules for CPU and memory.  
- Configure Alertmanager to handle alerts.  
- Implement a simple automated incident response using a shell script.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Set up monitoring rules in Prometheus.  
- Use Alertmanager to handle alerts.  
- Simulate system stress to trigger incidents.  
- Execute an automated response script.  

---

## 📋 Prerequisites  
- EC2 instance (Amazon Linux 2) from previous labs.  
- Prometheus + Alertmanager running (from **Lab 09**).  
- Node Exporter running on port **9100**.  
- Docker installed and working.  

---

## 🔨 Steps  

### Step 1: Verify Node Exporter is Running  
```bash
docker ps | grep node-exporter
````

✅ Expected: Node Exporter container running on port 9100.

---

### Step 2: Create Prometheus Alerting Rules

Navigate to Prometheus directory:

```bash
cd ~/prometheus-grafana
nano system-alerts.yml
```

Paste rules:

```yaml
groups:
  - name: system_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 75
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "High CPU usage on instance"
          description: "CPU usage exceeded 75% for more than 1 minute."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 80
        for: 1m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on instance"
          description: "Memory usage exceeded 80% for more than 1 minute."
```

Save and exit.

Update `prometheus.yml` to include rule file:

```yaml
rule_files:
  - "system-alerts.yml"
```

---

### Step 3: Restart Prometheus

```bash
docker-compose down
docker-compose up -d
```

Verify rules loaded:

```
http://<EC2_PUBLIC_IP>:9090/rules
```

✅ Expected: `HighCPUUsage` and `HighMemoryUsage` alerts listed.

---

### Step 4: Configure Alertmanager

Edit `alertmanager.yml`:

```bash
nano alertmanager.yml
```

Paste config:

```yaml
global:
  resolve_timeout: 5m

route:
  receiver: "default"

receivers:
  - name: "default"
    # Example webhook for automated response
    webhook_configs:
      - url: "http://localhost:5001/"
```

Save and exit.

Restart Alertmanager:

```bash
docker restart alertmanager
```

---

### Step 5: Implement Automated Response Script

Install Flask (for webhook):

```bash
sudo yum install -y python3-pip
pip3 install flask
```

Create response script:

```bash
nano incident_response.py
```

Paste:

```python
from flask import Flask, request

app = Flask(__name__)

@app.route('/', methods=['POST'])
def webhook():
    data = request.json
    print("🚨 Incident detected! Alert received:", data)
    # Example: automatic action could be restarting a service
    return "OK", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
```

Run the script:

```bash
python3 incident_response.py
```

✅ Expected: Web server running on port 5001.

---

### Step 6: Simulate Incident (Trigger Alert)

Install stress tool:

```bash
sudo yum install -y stress
```

Trigger CPU load:

```bash
stress --cpu 2 --timeout 120
```

Wait \~1 min. Check Prometheus Alerts page:

```
http://<EC2_PUBLIC_IP>:9090/alerts
```

✅ Expected: `HighCPUUsage` alert firing.

Check Flask log:

```
🚨 Incident detected! Alert received: {...}
```

---

## 🧾 Testing & Validation

1. **Verify Prometheus Rules:**

   ```bash
   curl http://localhost:9090/api/v1/rules | jq
   ```

   ✅ Expected: `HighCPUUsage`, `HighMemoryUsage` listed.

2. **Trigger Alert with stress:**

   ```bash
   stress --cpu 2 --timeout 120
   ```

   ✅ Expected: Prometheus alert becomes firing.

3. **Check Alertmanager:**

   ```
   http://<EC2_PUBLIC_IP>:9093
   ```

   ✅ Expected: Firing alert listed.

4. **Check Automated Response (Flask):**
   Console output should show alert JSON received.

---

## 📌 Further Learning (SRE Context)

* **This lab covers the Detect → Alert → Respond stages** of incident management.
* In production:

  * Webhook responses could trigger automated remediation (restart container, scale out).
  * Alerts should be integrated with PagerDuty, Slack, or OpsGenie.
  * Incidents should follow a **blameless postmortem process**.
* SREs aim to **reduce MTTR (Mean Time to Resolve)** with automation like this.

---

## ✅ Lab Completion

You have successfully:

* Created Prometheus alert rules for CPU and memory.
* Configured Alertmanager with webhook receiver.
* Implemented a simple automated response server with Flask.
* Simulated system load and observed detection + response.

This lab demonstrates **end-to-end incident monitoring, alerting, and automated response** — key SRE capabilities.


