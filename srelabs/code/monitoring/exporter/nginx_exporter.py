#!/usr/bin/env python3
from flask import Flask, Response
import requests
import os

app = Flask(__name__)

# inside compose, nginx service is reachable by hostname "nginx"
NGINX_STATUS_URL = os.environ.get("NGINX_STATUS_URL", "http://nginx:80/nginx_status")

@app.route("/metrics")
def metrics():
    try:
        r = requests.get(NGINX_STATUS_URL, timeout=2)
        r.raise_for_status()
        lines = r.text.splitlines()
    except Exception as e:
        # When nginx status can't be read, expose a prometheus metric indicating failure
        body = f'nginx_exporter_up 0\nnginx_exporter_error{{error="{type(e).__name__}"}} 1\n'
        return Response(body, mimetype="text/plain")

    # Parse expected stub_status format:
    # Active connections: 1
    # server accepts handled requests
    #  3 3 6
    # Reading: 0 Writing: 1 Waiting: 0
    metrics = []

    # Active connections
    try:
        metrics.append('nginx_active_connections ' + lines[0].split()[2])
    except Exception:
        pass

    # accepts handled requests
    try:
        accepts, handled, requests_total = map(int, lines[2].split())
        metrics.append(f'nginx_connections_accepted {accepts}')
        metrics.append(f'nginx_connections_handled {handled}')
        metrics.append(f'nginx_http_requests_total {requests_total}')
    except Exception:
        pass

    # Reading Writing Waiting
    try:
        parts = lines[3].replace(":", "").split()
        # parts should be ['Reading', '0', 'Writing', '1', 'Waiting', '0']
        metrics.append(f'nginx_reading {parts[1]}')
        metrics.append(f'nginx_writing {parts[3]}')
        metrics.append(f'nginx_waiting {parts[5]}')
    except Exception:
        pass

    # exporter up metric
    metrics.append("nginx_exporter_up 1")

    return Response("\n".join(metrics) + "\n", mimetype="text/plain")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=9113)

