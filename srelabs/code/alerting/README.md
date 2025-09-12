# Lab: Monitoring & Alerts with Prometheus and Alertmanager

## Objective
Set up Prometheus, Node Exporter, Nginx Prometheus Exporter and Alertmanager on one EC2 instance, then trigger an alert by stopping Nginx and observe that:
- Prometheus shows alert firing
- Alertmanager receives the alert and delivers to receiver

## Prereqs
- EC2 instance (Amazon Linux 2 or Ubuntu) with inbound ports 22, 80, 9090, 9093, 9100, 9113 open
- Shell access as ec2-user (sudo) or equivalent
- Internet access from the instance to download binaries

## Files
- `setup.sh` — run as root to install and configure everything
- `test.sh` — run to generate traffic and optionally to stop nginx for the demo
- `webhook_server.py` — simple webhook listener (started as systemd service by setup.sh)

---

## Run the lab

1. Upload `setup.sh`, `test.sh`, `webhook_server.py` to the EC2 instance and make executable:
   ```bash
   chmod +x setup.sh test.sh
   sudo ./setup.sh

