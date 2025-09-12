
---

## `setup.sh` (copy this file exactly; save as `setup.sh` and run with `sudo`)

```bash
#!/usr/bin/env bash
# setup.sh - installs Prometheus, Alertmanager, node_exporter, nginx-prometheus-exporter,
# nginx, Python3, Flask webhook, and creates systemd units and configs.
set -euo pipefail

# ----- Configurable versions -----
NODE_EXPORTER_VER="1.8.1"
NGINX_EXPORTER_VER="0.11.0"
PROMETHEUS_VER="2.53.1"
ALERTMANAGER_VER="0.27.0"

# ----- Paths -----
TMPDIR="/opt/tmp_monitoring"
PROM_DIR="/etc/prometheus"
AM_DIR="/etc/alertmanager"
PROM_VAR="/var/lib/prometheus"
AM_VAR="/var/lib/alertmanager"
BIN_DIR="/usr/local/bin"

# ----- Helpers -----
echoinfo(){ printf "\n[INFO] %s\n" "$*"; }
echowarn(){ printf "\n[WARN] %s\n" "$*"; }
echofatal(){ printf "\n[FATAL] %s\n" "$*"; exit 1; }

# detect package manager
if command -v yum >/dev/null 2>&1; then
  PKG_INSTALL="sudo yum install -y"
elif command -v apt-get >/dev/null 2>&1; then
  PKG_INSTALL="sudo apt-get update -y && sudo apt-get install -y"
else
  echowarn "Unknown package manager - you must install nginx, python3, pip3 manually"
  PKG_INSTALL=""
fi

# Create directories & users
sudo mkdir -p "${TMPDIR}" "${PROM_DIR}" "${AM_DIR}" "${PROM_VAR}" "${AM_VAR}"
sudo useradd --no-create-home --shell /sbin/nologin prometheus 2>/dev/null || true
sudo useradd --no-create-home --shell /sbin/nologin nodeexp 2>/dev/null || true

# Install base packages
if [ -n "$PKG_INSTALL" ]; then
  echoinfo "Installing base packages..."
  sudo ${PKG_INSTALL} wget tar gzip curl nano
  sudo ${PKG_INSTALL} nginx python3 python3-pip
fi

# Install Python Flask for webhook receiver
if ! command -v python3 >/dev/null 2>&1; then
  echowarn "python3 not found - please install python3"
fi
pip3 install --user flask >/dev/null 2>&1 || sudo pip3 install flask

# Download and install Node Exporter
cd "${TMPDIR}"
NE_ARCH="node_exporter-${NODE_EXPORTER_VER}.linux-amd64"
echoinfo "Downloading node_exporter ${NODE_EXPORTER_VER}..."
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VER}/${NE_ARCH}.tar.gz"
tar xzf "${NE_ARCH}.tar.gz"
sudo cp "${NE_ARCH}/node_exporter" "${BIN_DIR}/"
sudo chown nodeexp:nodeexp "${BIN_DIR}/node_exporter" || true

# Download and install Nginx Prometheus Exporter
echoinfo "Downloading nginx-prometheus-exporter ${NGINX_EXPORTER_VER}..."
wget -q "https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VER}/nginx-prometheus-exporter_${NGINX_EXPORTER_VER}_linux_amd64.tar.gz"
tar xzf "nginx-prometheus-exporter_${NGINX_EXPORTER_VER}_linux_amd64.tar.gz" || true
# exporter binary may be in current dir or inside archive
if [ -f "nginx-prometheus-exporter" ]; then
  sudo cp nginx-prometheus-exporter "${BIN_DIR}/"
elif [ -f "${TMPDIR}/nginx-prometheus-exporter" ]; then
  sudo cp "${TMPDIR}/nginx-prometheus-exporter" "${BIN_DIR}/"
fi
sudo chown root:root "${BIN_DIR}/nginx-prometheus-exporter" || true
# exporter listens on 9113 by default when run

# Download and install Prometheus
echoinfo "Downloading prometheus ${PROMETHEUS_VER}..."
PROM_ARCH="prometheus-${PROMETHEUS_VER}.linux-amd64"
wget -q "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VER}/${PROM_ARCH}.tar.gz"
tar xzf "${PROM_ARCH}.tar.gz"
sudo cp "${PROM_ARCH}/prometheus" "${BIN_DIR}/"
sudo cp "${PROM_ARCH}/promtool" "${BIN_DIR}/"
sudo chown root:root "${BIN_DIR}/prometheus" "${BIN_DIR}/promtool" || true

# Download and install Alertmanager
echoinfo "Downloading alertmanager ${ALERTMANAGER_VER}..."
AM_ARCH="alertmanager-${ALERTMANAGER_VER}.linux-amd64"
wget -q "https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VER}/${AM_ARCH}.tar.gz"
tar xzf "${AM_ARCH}.tar.gz"
sudo cp "${AM_ARCH}/alertmanager" "${BIN_DIR}/"
sudo cp "${AM_ARCH}/amtool" "${BIN_DIR}/"
sudo chown root:root "${BIN_DIR}/alertmanager" "${BIN_DIR}/amtool" || true

# create needed dirs and set ownership
sudo mkdir -p /etc/prometheus /var/lib/prometheus /etc/alertmanager /var/lib/alertmanager
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/alertmanager /var/lib/alertmanager

# Write Prometheus config
PRIVATE_IP=$(hostname -I | awk '{print $1}')
if [ -z "$PRIVATE_IP" ]; then PRIVATE_IP="127.0.0.1"; fi
echoinfo "Writing /etc/prometheus/prometheus.yml with private IP ${PRIVATE_IP}..."

sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'PROM'
global:
  scrape_interval: 15s
  scrape_timeout: 10s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['__PRIVATE_IP__:9100']

  - job_name: 'nginx'
    metrics_path: /metrics
    static_configs:
      - targets: ['__PRIVATE_IP__:9113']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['__PRIVATE_IP__:9093']

rule_files:
  - "/etc/prometheus/alert_rules.yml"
PROM
# inject real IP
sudo sed -i "s/__PRIVATE_IP__/${PRIVATE_IP}/g" /etc/prometheus/prometheus.yml

# Write alert rules
echoinfo "Writing /etc/prometheus/alert_rules.yml..."
sudo tee /etc/prometheus/alert_rules.yml > /dev/null <<'RULES'
groups:
- name: nginx_alerts
  rules:
  - alert: NginxDown
    expr: up{job="nginx"} == 0
    for: 10s
    labels:
      severity: critical
    annotations:
      summary: "Nginx is down"
      description: "Nginx exporter on {{ $labels.instance }} is unreachable."
RULES

# Write Alertmanager config with a simple webhook receiver (local Flask)
echoinfo "Writing /etc/alertmanager/alertmanager.yml..."
sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<'AM'
global:
  resolve_timeout: 1m

route:
  receiver: 'default'

receivers:
- name: 'default'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
AM

# Write webhook_server.py (simple Flask app)
echoinfo "Writing webhook receiver to /usr/local/bin/webhook_server.py..."
sudo tee /usr/local/bin/webhook_server.py > /dev/null <<'PY'
#!/usr/bin/env python3
from flask import Flask, request, jsonify
import logging
app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
@app.route('/', methods=['POST','GET'])
def receive():
    if request.method == 'POST':
        data = request.get_json(force=True, silent=True)
        app.logger.info("Received alert: %s", data)
        return jsonify({"status":"ok"}), 200
    return "Alert webhook receiver running\n"
PY
sudo chmod +x /usr/local/bin/webhook_server.py
sudo chown root:root /usr/local/bin/webhook_server.py

# systemd unit: node_exporter
echoinfo "Creating systemd unit for node_exporter..."
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

# systemd unit: nginx-prometheus-exporter
echoinfo "Creating systemd unit for nginx-prometheus-exporter..."
sudo tee /etc/systemd/system/nginx-prometheus-exporter.service > /dev/null <<'NGEX'
[Unit]
Description=Nginx Prometheus Exporter
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri http://127.0.0.1/stub_status
Restart=on-failure

[Install]
WantedBy=multi-user.target
NGEX

# systemd unit: prometheus
echoinfo "Creating systemd unit for prometheus..."
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

# systemd unit: alertmanager
echoinfo "Creating systemd unit for alertmanager..."
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

# systemd unit: webhook receiver
echoinfo "Creating systemd unit for webhook (Flask) receiver..."
sudo tee /etc/systemd/system/webhook.service > /dev/null <<'WEB'
[Unit]
Description=Simple Flask Webhook for Alertmanager
After=network-online.target

[Service]
User=root
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/python3 /usr/local/bin/webhook_server.py
Restart=always

[Install]
WantedBy=multi-user.target
WEB

# Ensure nginx stub_status is enabled: add location /stub_status in nginx conf if missing
echoinfo "Ensuring nginx stub_status endpoint exists in /etc/nginx/nginx.conf..."
if ! sudo grep -q "stub_status" /etc/nginx/nginx.conf 2>/dev/null; then
  # append location to default server block using a safe method
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

# Set ownership for security
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
sudo chown -R prometheus:prometheus /etc/alertmanager /var/lib/alertmanager
sudo chown root:root /usr/local/bin/{prometheus,promtool,alertmanager,amtool,nginx-prometheus-exporter} 2>/dev/null || true

# Reload systemd and start services
echoinfo "Reloading systemd units and starting services..."
sudo systemctl daemon-reload

sudo systemctl enable --now node_exporter
sudo systemctl enable --now nginx-prometheus-exporter
sudo systemctl enable --now webhook
sudo systemctl enable --now alertmanager
sudo systemctl enable --now prometheus

# Quick status summary
echoinfo "Services started. Status:"
sudo systemctl status prometheus --no-pager || true
sudo systemctl status alertmanager --no-pager || true
sudo systemctl status node_exporter --no-pager || true
sudo systemctl status nginx-prometheus-exporter --no-pager || true
sudo systemctl status webhook --no-pager || true

echoinfo "Prometheus UI: http://${PRIVATE_IP}:9090"
echoinfo "Alertmanager UI: http://${PRIVATE_IP}:9093"
echoinfo "Nginx metrics (nginx exporter): http://${PRIVATE_IP}:9113/metrics"
echoinfo "Node exporter: http://${PRIVATE_IP}:9100/metrics"

echoinfo "Setup complete. Use ./test.sh to generate traffic and trigger nginx stop to see alerts."

