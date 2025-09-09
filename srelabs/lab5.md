
# 🧪 Lab 05: Implementing Incident Management with Prometheus  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

Incident management is a critical responsibility for SREs. Using monitoring tools like **Prometheus**, we can detect when services go down, trigger alerts, and take action quickly.  

In this lab, you will configure Prometheus to monitor an **Nginx web server** and simulate an incident by stopping Nginx. You will then observe how Prometheus detects the outage.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Install and run Nginx on an EC2 instance.  
- Configure Prometheus to monitor Nginx.  
- Simulate an incident (Nginx down).  
- Observe alerts in Prometheus.  

---

## 📋 Prerequisites  
- EC2 instance (from **Lab 01**).  
- Prometheus installed and running (from **Lab 04**).  
- Security group inbound rules: open ports **80 (Nginx)** and **9090 (Prometheus)**.  

---

## 🔨 Steps  

### Step 1: Install Nginx  
Run the following commands in your EC2 terminal:  
```bash
sudo yum update -y
sudo yum install -y nginx
````

Enable and start Nginx:

```bash
sudo systemctl enable --now nginx
```

Verify Nginx is running:

```bash
curl http://localhost
```

✅ Expected: Default Nginx welcome page HTML.

---

### Step 2: Configure Prometheus to Monitor Nginx

Edit Prometheus configuration file:

```bash
nano ~/prometheus-grafana/prometheus.yml
```

Add a new job under `scrape_configs`:

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "nginx"
    static_configs:
      - targets: ["localhost:80"]
```

Save and exit.

---

### Step 3: Restart Prometheus

```bash
cd ~/prometheus-grafana
docker-compose down
docker-compose up -d
```

Verify Prometheus is running:

```bash
docker ps
```

---

### Step 4: Check Prometheus Targets

Open in browser:

```
http://<EC2_PUBLIC_IP>:9090/targets
```

✅ Expected:

* `prometheus` target → UP
* `nginx` target → UP

---

### Step 5: Simulate an Incident (Stop Nginx)

Stop Nginx service:

```bash
sudo systemctl stop nginx
```

---

### Step 6: Observe the Incident in Prometheus

Refresh Prometheus Targets page:

```
http://<EC2_PUBLIC_IP>:9090/targets
```

✅ Expected:

* `nginx` target status → **DOWN**

You can also run a query in Prometheus UI:

```promql
up{job="nginx"}
```

Expected: `0` (indicating Nginx is down).

---

## 🧾 Testing & Validation

1. Check Nginx is running initially:

   ```bash
   systemctl status nginx
   ```

   ✅ Expected: active (running).

2. Verify Prometheus shows Nginx target UP.

3. Stop Nginx:

   ```bash
   sudo systemctl stop nginx
   ```

   ✅ Expected: Nginx target becomes DOWN in Prometheus.

4. Restart Nginx to recover:

   ```bash
   sudo systemctl start nginx
   ```

   ✅ Expected: Nginx target returns to UP.

---

## 📌 Further Learning (SRE Context)

* This lab demonstrates the **detection** part of incident management.
* In real-world SRE practice:

  * **Detection** → Identify service failure (Prometheus Target DOWN).
  * **Triage** → Investigate root cause.
  * **Mitigation** → Restart service, reroute traffic, or scale up.
  * **Postmortem** → Document incident in a blameless report.
* In later labs, you will integrate **Alertmanager** to send alerts to email/Slack and automate responses.

---

## ✅ Lab Completion

You have successfully:

* Installed and configured Nginx.
* Configured Prometheus to monitor Nginx.
* Simulated an incident by stopping Nginx.
* Verified that Prometheus detected the outage.

This prepares you for **toil reduction and automated recovery** in the next lab.


