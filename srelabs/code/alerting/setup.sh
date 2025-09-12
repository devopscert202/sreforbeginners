#!/usr/bin/env bash
# setup.sh - Full lab installer for Prometheus / Alertmanager / exporters / webhook + systemd units
# Intended for lab demo only (Amazon Linux 2, RHEL, Fedora, Ubuntu tested paths)
set -euo pipefail

### Configuration - change versions here if needed
NODE_EXPORTER_VER="1.8.1"
NGINX_EXPORTER_VER="0.11.0"
PROMETHEUS_VER="2.53.1"
ALERTMANAGER_VER="0.27.0"

TMPDIR="/opt/tmp_monitoring"
BIN_DIR="/usr/local/bin"
PROM_DIR="/etc/prometheus"
AM_DIR="/etc/alertmanager"
PROM_VAR="/var/lib/prometheus"
AM_VAR="/var/lib/alertmanager"
WEBHOOK_PORT=5001
WEBHOOK_BIND="127.0.0.1"
WEBHOOK_URL="http://${WEBHOOK_BIND}:${WEBHOOK_PORT}/"

echo
echo "---- Monitoring lab setup starting ----"
echo "Will install to: ${BIN_DIR}, configs under: ${PROM_DIR}, ${AM_DIR}"
echo

# detect package manager
if command -v yum >/dev/null 2>&1; then
  PKG_INSTALL="sudo yum install -y"
  PKG_UPDATE="sudo yum update -y"
elif command -v apt-get >/dev/null 2>&1; then
  PKG_INSTALL="sudo apt-get install -y"
  PKG_UPDATE="sudo apt-get update -y"
else
  echo "No supported package manager found (yum/apt-get). Install dependencies manually." >&2
  PKG_INSTALL=""
  PKG_UPDATE=""
fi

# Create working dir
sudo mkdir -p "${TMPDIR}"
sudo chown "$(id -u):$(id -g)" "${TMPDIR}"

# Basic packages
if [ -n "$PKG_UPDATE" ]; then
  echo "[INFO] Updating package lists and installing base packages..."
  eval "${PKG_UPDATE}"
fi

if [ -n "$PKG_INSTALL" ]; then
  echo "[INFO] Installing wget, tar, gzip, curl, python3, pip3, nginx ..."
  # apt vs yum: package name differences handled by package manager
  eval "${PKG_INSTALL} wget tar gzip python3 python3-pip nginx"
fi

# Ensure pip3 exists
if ! command -v pip3 >/dev/null 2>&1; then
  echo "[WARN] pip3 not found; attempting to install python3-pip..."
  if [ -n "$PKG_INSTALL" ]; then
    eval "${PKG_INSTALL} python3-pip"
  fi
fi

# Install Flask (system-wide so systemd can import)
echo "[INFO] Installing Flask via pip3..."
sudo pip3 install --upgrade pip >/dev/null 2>&1 || true
sudo pip3 install flask >/dev/null 2>&1 || true

# Create users
sudo useradd --no-create-home --shell /sbin/nologin prometheus 2>/dev/null || true
sudo useradd --no-create-home --shell /sbin/nologin nodeexp 2>/dev/null || true

# Create dirs
sudo mkdir -p "${PROM_DIR}" "${AM_DIR}" "${PROM_VAR}" "${AM_VAR}"
sudo chown -R prometheus:prometheus "${PROM_DIR}" "${PROM_VAR}" "${AM_DIR}" "${AM_VAR}" || true

cd "${TMPDIR}"

### Download and install Node Exporter
echo "[INFO] Downloading node_exporter v${NODE_EXPORTER_VER}..."
NE_ARCH="node_exporter-${NODE_EXPORTER_VER}.linux-amd64"
wget -q -O "${NE_ARCH}.tar.gz" "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/${NE_ARCH}.tar.gz"
tar xzf "${NE_ARCH}.tar.gz"
sudo cp "${NE_ARCH}/node_exporter" "${BIN_DIR}/"
sudo chown nodeexp:nodeexp "${BIN_DIR}/node_exporter" || true

### Download and install Nginx Prometheus Exporter
echo "[INFO] Downloading nginx-prometheus-exporter v${NGINX_EXPORTER_VER}..."
# the nginx exporter release has various archive names; use the generic linux_amd64 tar
NGX_EX_ARCH="nginx-prometheus-exporter_${NGINX_EXPORTER_VER}_linux_amd64"
wget -q -O "${NGX_EX_ARCH}.tar.gz" "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VER}/${NGX_EX_ARCH}.tar.gz"
tar xzf "${NGX_EX_ARCH}.tar.gz" || true
# Copy binary (try common locations)
if [ -f "nginx-prometheus-exporter" ]; then
  sudo cp nginx-prometheus-exporter "${BIN_DIR}/"
elif [ -f "${NGX_EX_ARCH}/nginx-prometheus-exporter" ]; then
  sudo cp "${NGX_EX_ARCH}/nginx-prometheus-exporter" "${BIN_DIR}/"
else
  # try to find binary in extracted dir
  found=$(find . -maxdepth 2 -type f -name 'nginx-prometheus-exporter*' | head -n1 || true)
  if [ -n "$found" ]; then
    sudo cp "$found" "${BIN_DIR}/nginx-prometheus-exporter"
  else
    echo "[WARN] nginx-prometheus-exporter binary not found in archive; skipping binary copy." >&2
  fi
fi
sudo chown root:root "${BIN_DIR}/nginx-prometheus-exporter" || true
sudo chmod 755 "${BIN_DIR}/nginx-prometheus-exporter" || true

### Download and install Prometheus
echo "[INFO] Downloading Prometheus v${PROMETHEUS_VER}..."
PROM_ARCH="prometheus-${PROMETHEUS_VER}.linux-amd64"
wget -q -O "${PROM_ARCH}.tar.gz" "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VER}/${PROM_ARCH}.tar.gz"
tar xzf "${PROM_ARCH}.tar.gz"
sudo cp "${PROM_ARCH}/prometheus" "${BIN_DIR}/"
sudo cp "${PROM_ARCH}/promtool" "${BIN_DIR}/"
sudo chown root:root "${BIN_DIR}/prometheus" "${BIN_DIR}/promtool" || true
sudo chmod 755 "${BIN_DIR}/prometheus" "${BIN_DIR}/promtool"

### Download and install Alertmanager
echo "[INFO] Downloading Alertmanager v${ALERTMANAGER_VER}..."
AM_ARCH="alertmanager-${ALERTMANAGER_VER}.linux-amd64"
wget -q -O "${AM_ARCH}.tar.gz" "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VER}/${AM_ARCH}.tar.gz"
tar xzf "${AM_ARCH}.tar.gz"
sudo cp "${AM_ARCH}/alertmanager" "${BIN_DIR}/"
sudo cp "${AM_ARCH}/amtool" "${BIN_DIR}/"
sudo chown root:root "${BIN_DIR}/alertmanager" "${BIN_DIR}/amtool" || true
sudo chmod 755 "${BIN_DIR}/alertmanager" "${BIN_DIR}/amtool"

### Ensure /usr/local/bin is in PATH for systemd ExecStart (it usually is)
echo "[INFO] Binaries installed to ${BIN_DIR}:"
ls -l "${BIN_DIR}/prometheus" "${BIN_DIR}/promtool" "${BIN_DIR}/alertmanager" "${BIN_DIR}/amtool" "${BIN_DIR}/node_exporter" "${BIN_DIR}/nginx-prometheus-exporter" 2>/dev/null || true

### Write Prometheus config with rule_files included
echo "[INFO] Writing Prometheus config..."
PRIVATE_IP=$(hostname -I | awk '{print $1}' || echo "127.0.0.1")
if [ -z "${PRIVATE_IP}" ]; then PRIVATE_IP="127.0.0.1"; fi

sudo tee "${PROM_DIR}/prometheus.yml" > /dev/null <<PROM
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "${PROM_DIR}/alert_rules.yml"

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['127.0.0.1:9100']

  - job_name: 'nginx'
    metrics_path: /metrics
    static_configs:
      - targets: ['127.0.0.1:9113']

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - '127.0.0.1:9093'
PROM

# Write alert rules (comprehensive rules)
echo "[INFO] Writing Prometheus alert rules..."
sudo tee "${PROM_DIR}/alert_rules.yml" > /dev/null <<RULES
groups:
- name: nginx_alerts
  rules:

  - alert: NginxExporterScrapeFailed
    expr: nginxexporter_last_scrape_error > 0
    for: 15s
    labels:
      severity: critical
    annotations:
      summary: "Nginx exporter scrape failed on {{ \$labels.instance }}"
      description: "The nginx prometheus exporter reports scrape errors. Nginx may be stopped or unreachable."

  - alert: NginxExporterDown
    expr: up{job="nginx"} == 0
    for: 15s
    labels:
      severity: critical
    annotations:
      summary: "Nginx exporter target down on {{ \$labels.instance }}"
      description: "Prometheus reports the nginx exporter job as down. Check exporter process & nginx stub_status."

  - alert: NginxMetricsMissing
    expr: absent(nginx_http_requests_total)
    for: 30s
    labels:
      severity: critical
    annotations:
      summary: "Nginx metrics missing for {{ \$labels.instance }}"
      description: "Prometheus cannot see nginx_http_requests_total. This usually means exporter cannot scrape nginx."

  - alert: NginxNoTraffic
    expr: increase(nginx_http_requests_total[5m]) == 0
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "No HTTP requests to Nginx for 5m on {{ \$labels.instance }}"
      description: "There have been no HTTP requests to nginx in the last 5 minutes (may indicate outage or traffic routing issue)."

  - alert: NginxHighErrors
    expr: increase(nginx_http_responses_total{status=~"5.."}[5m]) > 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Nginx serving 5xx responses on {{ \$labels.instance }}"
      description: "Nginx is returning 5xx responses (server errors). Check upstream/backends and resource use."

  - alert: NginxDown
    expr: (nginxexporter_last_scrape_error > 0) OR absent(nginx_http_requests_total)
    for: 15s
    labels:
      severity: critical
    annotations:
      summary: "Nginx likely down or unreachable on {{ \$labels.instance }}"
      description: |
        One or more signals indicate nginx is down:
        - exporter scrape error OR
        - nginx metrics missing.
        Check nginx service, exporter, and network connectivity.
RULES

# Alertmanager config with webhook receiver
echo "[INFO] Writing Alertmanager config..."
sudo tee "${AM_DIR}/alertmanager.yml" > /dev/null <<AM
global:
  resolve_timeout: 1m

route:
  receiver: 'webhook-default'
  group_wait: 10s
  group_interval: 1m
  repeat_interval: 1m

receivers:
  - name: 'webhook-default'
    webhook_configs:
      - url: '${WEBHOOK_URL}'
        send_resolved: true
AM

# Write webhook_server.py (verbose, systemd-friendly)
echo "[INFO] Writing webhook_server.py..."
sudo tee /usr/local/bin/webhook_server.py > /dev/null <<'PY'
#!/usr/bin/env python3
"""
webhook_server.py - verbose Flask webhook receiver suitable for systemd
"""
import os, sys, socket, logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
from flask import Flask, request, jsonify

HOST = "127.0.0.1"
PORT = 5001
PID_FILE = "/var/run/webhook_server.pid"
LOG_FILE = "/var/log/webhook_server.log"

logger = logging.getLogger("webhook_server")
logger.setLevel(logging.INFO)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
ch.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
logger.addHandler(ch)
try:
    fh = RotatingFileHandler(LOG_FILE, maxBytes=5*1024*1024, backupCount=3)
    fh.setLevel(logging.INFO)
    fh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(fh)
except Exception as e:
    logger.warning("Could not create file handler %s: %s", LOG_FILE, e)

app = Flask(__name__)

def write_pid(pid_path=PID_FILE):
    try:
        dirn = os.path.dirname(pid_path)
        if dirn and not os.path.exists(dirn):
            os.makedirs(dirn, exist_ok=True)
        with open(pid_path, "w") as f:
            f.write(str(os.getpid()))
        logger.info("Wrote PID %s -> %s", os.getpid(), pid_path)
    except Exception as e:
        logger.exception("Failed to write pid file: %s", e)

def check_port_free(host, port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s.settimeout(1.0)
        result = s.connect_ex((host, port))
        return result != 0
    except Exception:
        return False
    finally:
        s.close()

@app.route("/", methods=["GET","POST"])
def receive():
    try:
        if request.method == "POST":
            payload = request.get_json(force=False, silent=True)
            if payload is None:
                text = request.get_data(as_text=True)
                logger.info("Received POST (non-JSON). Raw: %s", text[:1000])
            else:
                logger.info("Received POST JSON (truncated): %s", str(payload)[:1000])
            return jsonify({"status": "received", "time": datetime.utcnow().isoformat()}), 200
        else:
            return ("Webhook receiver running\n", 200)
    except Exception:
        logger.exception("Error handling request")
        return ("internal error\n", 500)

def startup_checks():
    logger.info("Starting startup checks...")
    logger.info("Python: %s", sys.version.replace("\\n"," "))
    try:
        import flask
        logger.info("Flask version: %s", flask.__version__)
    except Exception as e:
        logger.exception("Flask import failed: %s", e)
        raise
    if not check_port_free(HOST, PORT):
        logger.error("Port %s:%s appears to be IN USE. Aborting.", HOST, PORT)
        raise SystemExit(1)
    logger.info("Port %s:%s is free.", HOST, PORT)

if __name__ == "__main__":
    try:
        startup_checks()
        write_pid()
        logger.info("Starting Flask webhook on http://%s:%s (use_reloader=False)", HOST, PORT)
        app.run(host=HOST, port=PORT, debug=False, use_reloader=False)
    except SystemExit as e:
        logger.exception("Exiting due to SystemExit: %s", e)
        raise
    except Exception as e:
        logger.exception("Unhandled exception during startup: %s", e)
        sys.exit(1)
PY

sudo chmod 755 /usr/local/bin/webhook_server.py
sudo chown root:root /usr/local/bin/webhook_server.py || true

# Ensure nginx stub_status endpoint exists (create conf under conf.d)
echo "[INFO] Ensuring nginx stub_status endpoint..."
if ! sudo grep -q "stub_status" /etc/nginx/nginx.conf 2>/dev/null; then
  sudo tee /etc/nginx/conf.d/stub_status.conf > /dev/null <<'STUB'
server {
    listen 127.0.0.1:80;
    server_name  localhost;
    location /stub_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
STUB
fi

# Create systemd unit files

# node_exporter
echo "[INFO] Writing systemd unit: node_exporter.service"
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'NE'
[Unit]
Description=Prometheus Node Exporter
After=network-online.target
Wants=network-online.target

[Service]
User=nodeexp
Group=nodeexp
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
NE

# nginx-prometheus-exporter
echo "[INFO] Writing systemd unit: nginx-prometheus-exporter.service"
sudo tee /etc/systemd/system/nginx-prometheus-exporter.service > /dev/null <<'NGEX'
[Unit]
Description=Nginx Prometheus Exporter
After=network-online.target nginx.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri http://127.0.0.1/stub_status
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
NGEX

# prometheus
echo "[INFO] Writing systemd unit: prometheus.service"
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'PROMU'
[Unit]
Description=Prometheus
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure

[Install]
WantedBy=multi-user.target
PROMU

# alertmanager
echo "[INFO] Writing systemd unit: alertmanager.service"
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<'AMU'
[Unit]
Description=Alertmanager
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=on-failure

[Install]
WantedBy=multi-user.target
AMU

# webhook
echo "[INFO] Writing systemd unit: webhook.service"
sudo tee /etc/systemd/system/webhook.service > /dev/null <<'WEB'
[Unit]
Description=Simple Flask Webhook for Alertmanager
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 -u /usr/local/bin/webhook_server.py
Restart=on-failure
RestartSec=5
StartLimitBurst=10
StartLimitIntervalSec=60
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
WEB

# Ensure permissions
sudo chown -R prometheus:prometheus "${PROM_DIR}" "${PROM_VAR}" || true
sudo chmod 644 "${PROM_DIR}/prometheus.yml" "${PROM_DIR}/alert_rules.yml" || true

# Reload systemd and start services
echo "[INFO] Reloading systemd, enabling & starting services..."
sudo systemctl daemon-reload

sudo systemctl enable --now node_exporter
sudo systemctl enable --now nginx-prometheus-exporter
sudo systemctl enable --now webhook
sudo systemctl enable --now alertmanager
sudo systemctl enable --now prometheus

# Wait a bit and show status
sleep 2
echo
echo "---- Service statuses (short) ----"
sudo systemctl status prometheus --no-pager | sed -n '1,4p' || true
sudo systemctl status alertmanager --no-pager | sed -n '1,4p' || true
sudo systemctl status node_exporter --no-pager | sed -n '1,4p' || true
sudo systemctl status nginx-prometheus-exporter --no-pager | sed -n '1,4p' || true
sudo systemctl status webhook --no-pager | sed -n '1,6p' || true

echo
echo "---- Quick validation ----"
echo "Prometheus UI: http://127.0.0.1:9090 (targets: /targets, rules: /rules, alerts: /alerts)"
echo "Alertmanager UI: http://127.0.0.1:9093"
echo "Webhook: ${WEBHOOK_URL}"
echo "Nginx exporter metrics: http://127.0.0.1:9113/metrics"
echo "Node exporter: http://127.0.0.1:9100/metrics"

echo
echo "You can run these checks now:"
echo "  curl http://127.0.0.1:9090/api/v1/targets | jq ."
echo "  curl http://127.0.0.1:9090/api/v1/rules | jq ."
echo "  curl -s http://127.0.0.1:9090/api/v1/alertmanagers | jq ."
echo "  curl -s http://127.0.0.1:9093/api/v2/alerts | jq ."
echo "To test webhook delivery manually:"
echo "  echo '[{\"labels\":{\"alertname\":\"ManualTest\",\"severity\":\"critical\"},\"annotations\":{\"summary\":\"manual\"},\"startsAt\":\"'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'\"}]' | curl -s -H 'Content-Type: application/json' -d @- http://127.0.0.1:9093/api/v2/alerts"
echo
echo "---- Setup complete ----"


sudo systemctl status --now node_exporter
sudo systemctl status --now nginx-prometheus-exporter
sudo systemctl status --now webhook
sudo systemctl status --now alertmanager
sudo systemctl status --now prometheus
