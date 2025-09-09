# 🧪 Lab 14: Implementing Container Restart Detection and Alerting with Docker  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

A key SRE responsibility is **detecting failures quickly**. Docker containers may restart repeatedly due to crashes, resource limits, or misconfigurations. Detecting frequent restarts allows SREs to investigate and prevent cascading failures.  

In this lab, you will:  
- Deploy a simple container.  
- Write a shell script to detect restart events.  
- Trigger simulated restarts.  
- Send alerts (console output / log entries) when restarts exceed a threshold.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Monitor Docker containers for restarts.  
- Trigger alerting logic if restarts exceed a threshold.  
- Simulate failure and validate detection.  

---

## 📋 Prerequisites  
- EC2 instance with Docker installed.  
- Basic Linux shell knowledge.  
- Security group inbound rules: allow ports if your container exposes any service.  

---

## 🔨 Steps  

### Step 1: Run a Sample Container  
Run a simple `nginx` container:  
```bash
docker run -d --name mynginx -p 8080:80 nginx
````

Verify:

```bash
docker ps | grep mynginx
```

---

### Step 2: Create Restart Detection Script

```bash
mkdir ~/restart-monitor
cd ~/restart-monitor
nano detect_restarts.sh
```

Paste the script:

```bash
#!/bin/bash
# detect_restarts.sh - Monitor Docker container restarts
# Logs alerts if restart count exceeds threshold

CONTAINER_NAME="mynginx"
THRESHOLD=3
LOGFILE="$HOME/restart-monitor/restart_alerts.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Get restart count
RESTARTS=$(docker inspect --format='{{ .RestartCount }}' $CONTAINER_NAME 2>/dev/null)

if [ -z "$RESTARTS" ]; then
  echo "$DATE: ERROR - Container $CONTAINER_NAME not found" >> "$LOGFILE"
  exit 1
fi

if [ "$RESTARTS" -gt "$THRESHOLD" ]; then
  echo "$DATE: ALERT - $CONTAINER_NAME has restarted $RESTARTS times!" >> "$LOGFILE"
else
  echo "$DATE: OK - $CONTAINER_NAME restart count = $RESTARTS" >> "$LOGFILE"
fi
```

Save and exit.

Make script executable:

```bash
chmod +x detect_restarts.sh
```

---

### Step 3: Test Script Initially

Run script:

```bash
./detect_restarts.sh
cat restart_alerts.log
```

✅ Expected:

```
YYYY-MM-DD HH:MM:SS: OK - mynginx restart count = 0
```

---

### Step 4: Simulate Container Failures

Stop and remove the container multiple times:

```bash
docker stop mynginx
docker rm mynginx
docker run -d --name mynginx -p 8080:80 nginx
```

Repeat above 4–5 times. Each restart increments restart count.

---

### Step 5: Re-run Detection Script

```bash
./detect_restarts.sh
cat restart_alerts.log
```

✅ Expected:
If restart count > 3, log shows:

```
YYYY-MM-DD HH:MM:SS: ALERT - mynginx has restarted 4 times!
```

---

### Step 6: Automate Monitoring with cron

Schedule script to run every 5 minutes:

```bash
crontab -e
```

Add line:

```cron
*/5 * * * * /home/ec2-user/restart-monitor/detect_restarts.sh
```

Save and exit.

Check scheduled jobs:

```bash
crontab -l
```

---

## 🧾 Testing & Validation

1. **Initial Run (no failures)**

   ```bash
   ./detect_restarts.sh
   ```

   ✅ Expected: “OK” log entry with restart count = 0.

2. **Simulated Restarts**
   Restart container multiple times.

   ```bash
   ./detect_restarts.sh
   ```

   ✅ Expected: “ALERT” log entry with restart count > 3.

3. **Cron Validation**
   Wait \~5 minutes after configuring cron.

   ```bash
   tail -n 5 restart_alerts.log
   ```

   ✅ Expected: Script runs automatically and logs results.

---

## 📌 Further Learning (SRE Context)

* Frequent container restarts may indicate **crash loops** or **resource exhaustion**.
* In production:

  * Alerts should integrate with **Prometheus Alertmanager, Slack, PagerDuty**.
  * Auto-recovery actions may restart services or scale replicas.
* This lab connects to **toil reduction**: instead of manual monitoring, automation detects restarts proactively.

---

## ✅ Lab Completion

You have successfully:

* Deployed a test container.
* Created a restart detection script.
* Simulated container failures.
* Automated detection with cron.

This lab demonstrates **observability + proactive incident detection** — essential SRE practices.
ctly to GitHub?
```
