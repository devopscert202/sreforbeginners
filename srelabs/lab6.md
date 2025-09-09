## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  
One of the core SRE goals is to **reduce toil** — repetitive, manual work that can (and should) be automated. In this lab you'll implement a simple **self-healing** mechanism: a shell script that checks whether an `nginx` Docker container is running and, if not, restarts or recreates it. You will then schedule the script via `cron` so it runs periodically and provides continuous automated recovery.

This is a practical, safe example of toil reduction suitable for a fresher cohort. In production, self-healing would be combined with alerting and proper orchestration (e.g., Kubernetes, systemd units, or platform autoscaling).

---

## 🎯 Objective  
By the end of this lab you will be able to:

- Run Nginx in Docker on an EC2 instance.
- Create a robust, idempotent auto-recovery shell script that restarts or recreates the `nginx` container.
- Test the script manually and observe recovery behavior.
- Schedule the script with `cron` for periodic automatic execution.
- Validate end-to-end automation (stop container → script recovers it).

---

## 📋 Prerequisites  

- EC2 instance (Amazon Linux 2) from **Lab 01**.  
- Docker installed and running. If not yet installed, the steps below include Docker installation commands.  
- Basic familiarity with Linux shell and `nano` editor.

---

## 🔨 Steps  

> **Note:** Commands in the doc are preserved; I have corrected syntax where needed and added clarifying comments. Execute commands on your EC2 instance terminal as `ec2-user` (use `sudo` where shown).

### Step 1 — Install Docker and Prepare Environment
If Docker is not installed on your instance, run:

```bash
sudo yum update -y
sudo yum install -y docker
sudo systemctl enable --now docker
````

Add `ec2-user` to the `docker` group (so you can run Docker without `sudo`):

```bash
sudo usermod -aG docker ec2-user
# Apply group changes to current session
newgrp docker
```

**Optional:** Reboot the instance if group changes don't take effect:

```bash
sudo reboot
# After reboot, re-connect via SSH and continue
```

Verify Docker is available:

```bash
docker --version
docker info
```

---

### Step 2 — Pull and Run Nginx Container

Pull the latest Nginx image and run the container:

```bash
docker pull nginx:latest
docker run -d --name nginx -p 80:80 nginx:latest
```

Verify container is running:

```bash
docker ps
# You should see a container named "nginx" in the list
```

Quick HTTP check (from the EC2 instance):

```bash
curl -I http://localhost
# Expect HTTP/1.1 200 OK (or similar headers)
```

---

### Step 3 — Create Auto-Recovery Script

Create working directory and script file:

```bash
mkdir -p ~/sre-foundations/lab5-toil
cd ~/sre-foundations/lab5-toil
nano check_nginx.sh
```

Paste the following content into `check_nginx.sh` (this is a robust version with comments and safe checks):

```bash
#!/bin/bash
# check_nginx.sh - auto-recover nginx Docker container
# Writes logs to $LOG and attempts to start/create nginx container if missing.

LOG="$HOME/sre-foundations/lab5-toil/nginx_auto_recovery.log"
DOCKER_BIN="$(command -v docker || true)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

# Ensure docker binary exists
if [ -z "$DOCKER_BIN" ]; then
  echo "$DATE: ERROR - docker not found in PATH" >> "$LOG"
  exit 1
fi

# Check if container named 'nginx' is running
if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx nginx; then
  echo "$DATE: WARN  - nginx container not running. Attempting recovery..." >> "$LOG"

  # If a stopped container exists, start it
  if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -qx nginx; then
    if $DOCKER_BIN start nginx >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container started successfully." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to start existing nginx container." >> "$LOG"
    fi
  else
    # No container exists; create and run it
    if $DOCKER_BIN run -d --name nginx -p 80:80 nginx:latest >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container created and started." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to create/start nginx container." >> "$LOG"
    fi
  fi
else
  echo "$DATE: OK    - nginx is running." >> "$LOG"
fi
```

Save the file (`CTRL+O`, Enter) and exit (`CTRL+X`).

Make script executable:

```bash
chmod +x check_nginx.sh
```

---

### Step 4 — Test the Script Manually

Run the script manually and tail the log to confirm behavior:

```bash
./check_nginx.sh
tail -n 10 nginx_auto_recovery.log
```

You should see a log entry such as:

```
2025-09-09 12:34:56: OK    - nginx is running.
```

---

### Step 5 — Simulate Failure and Verify Recovery

Stop the nginx container to simulate failure:

```bash
docker stop nginx
```

Now run the script again:

```bash
./check_nginx.sh
tail -n 20 nginx_auto_recovery.log
```

Expected log entries:

* A `WARN` entry stating container not running.
* An `INFO` that container was started or recreated.

Verify container is back up:

```bash
docker ps | grep nginx
curl -I http://localhost
# Expect 200 OK headers again
```

---

### Step 6 — Schedule the Script with cron

Install and enable cron if not present (Amazon Linux 2: `cronie`):

```bash
sudo yum install -y cronie
sudo systemctl enable --now crond
```

Edit the crontab for `ec2-user`:

```bash
crontab -e
```

Add the following lines at the bottom of the crontab (this will run the script every 2 minutes):

```cron
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

*/2 * * * * /home/ec2-user/sre-foundations/lab5-toil/check_nginx.sh >> /home/ec2-user/sre-foundations/lab5-toil/cron_run.log 2>&1
```

Save and exit the editor. The cron daemon will pick up the job automatically.

**Verify the cron job is installed:**

```bash
crontab -l
# Expect to see the cron line you added
```

---

### Step 7 — Validate End-to-End Automation

1. Stop the nginx container:

```bash
docker stop nginx
```

2. Wait up to 2 minutes for cron to trigger the script. Then check:

```bash
tail -n 50 ~/sre-foundations/lab5-toil/nginx_auto_recovery.log
cat ~/sre-foundations/lab5-toil/cron_run.log
docker ps | grep nginx
curl -I http://localhost
```

**Expected:**

* `nginx_auto_recovery.log` shows recovery attempts and success.
* `cron_run.log` contains cron execution records (if any script output).
* `docker ps` shows the `nginx` container running.
* `curl -I http://localhost` returns HTTP headers (200 OK).

---

### Step 8 — Cleanup (Optional)

If you want to remove the cron job and cleanup artifacts:

Remove cron job entry:

```bash
# Open crontab and remove the entry manually:
crontab -e
# (delete the line added earlier, save & exit)
```

Remove container and files:

```bash
docker rm -f nginx || true
rm -rf ~/sre-foundations/lab5-toil
```

---

## 🧾 Testing & Validation (Consolidated)

Run these checks to confirm success:

1. **Script syntax & permissions**

   ```bash
   ls -l ~/sre-foundations/lab5-toil/check_nginx.sh
   # Expect: -rwxr-xr-x or similar (executable)
   ```

2. **Manual run success**

   ```bash
   ./check_nginx.sh
   tail -n 5 nginx_auto_recovery.log
   # Expect: OK - nginx is running OR INFO - started/recreated
   ```

3. **Simulate failure & confirm recovery**

   ```bash
   docker stop nginx
   ./check_nginx.sh
   docker ps | grep nginx
   # Expect: nginx is running after script
   ```

4. **Cron-based automatic recovery**

   ```bash
   docker stop nginx
   sleep 130   # wait slightly more than 2 minutes
   tail -n 50 ~/sre-foundations/lab5-toil/nginx_auto_recovery.log
   docker ps | grep nginx
   # Expect: nginx recovered by cron-invoked script
   ```

---

## 📌 Further Learning (SRE Context)

* **Why this matters:** Automating repetitive recovery tasks reduces toil, improves mean time to repair (MTTR), and frees engineers for higher-value work.
* **Limitations:** This script is intentionally simple for teaching. In production consider:

  * Proper alerting (Alertmanager, Slack, PagerDuty) when automatic recovery happens.
  * Rate limiting and exponential backoff for retries to avoid tight failure loops.
  * Secure logging, log rotation, and centralized logs.
  * Using orchestration (Kubernetes deployments with liveness/readiness probes) or systemd services for more robust auto-restart.
* **Next steps:** Integrate this automated recovery with Prometheus alerts and a blameless postmortem practice when repeated recoveries indicate deeper issues.

---

## ✅ Lab Completion

You have successfully:

* Deployed an `nginx` Docker container.
* Implemented a resilient auto-recovery shell script.
* Tested manual and cron-based recovery behavior.
* Validated the end-to-end automation and observed expected outcomes.

This lab demonstrates a simple, practical approach to reducing toil — a core SRE objective.

---

## Appendix — Full Script (for copy/paste)

```bash
#!/bin/bash
# check_nginx.sh - auto-recover nginx Docker container
LOG="$HOME/sre-foundations/lab5-toil/nginx_auto_recovery.log"
DOCKER_BIN="$(command -v docker || true)"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"
if [ -z "$DOCKER_BIN" ]; then
  echo "$DATE: ERROR - docker not found in PATH" >> "$LOG"
  exit 1
fi
if ! $DOCKER_BIN ps --format '{{.Names}}' | grep -qx nginx; then
  echo "$DATE: WARN  - nginx container not running. Attempting recovery..." >> "$LOG"
  if $DOCKER_BIN ps -a --format '{{.Names}}' | grep -qx nginx; then
    if $DOCKER_BIN start nginx >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container started successfully." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to start existing nginx container." >> "$LOG"
    fi
  else
    if $DOCKER_BIN run -d --name nginx -p 80:80 nginx:latest >/dev/null 2>&1; then
      echo "$DATE: INFO  - nginx container created and started." >> "$LOG"
    else
      echo "$DATE: ERROR - failed to create/start nginx container." >> "$LOG"
    fi
  fi
else
  echo "$DATE: OK    - nginx is running." >> "$LOG"
fi
```


