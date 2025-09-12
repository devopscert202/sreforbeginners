#!/usr/bin/env python3
"""
webhook_server.py
Simple, verbose Flask webhook receiver for Alertmanager.

- Binds to 127.0.0.1:5001 by default (change HOST/PORT below if needed)
- Writes logs to stdout and /var/log/webhook_server.log
- Disables Flask reloader so the process does not fork (important for systemd)
- Writes a PID file to /var/run/webhook_server.pid
"""

import os
import sys
import socket
import logging
from logging.handlers import RotatingFileHandler
from datetime import datetime
from flask import Flask, request, jsonify

# Config
HOST = "127.0.0.1"
PORT = 5001
PID_FILE = "/var/run/webhook_server.pid"
LOG_FILE = "/var/log/webhook_server.log"
LOG_MAX_BYTES = 5 * 1024 * 1024
LOG_BACKUP_COUNT = 3

# Create logger
logger = logging.getLogger("webhook_server")
logger.setLevel(logging.INFO)

# Console handler (stderr/stdout)
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
ch.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
logger.addHandler(ch)

# File handler (rotating)
try:
    fh = RotatingFileHandler(LOG_FILE, maxBytes=LOG_MAX_BYTES, backupCount=LOG_BACKUP_COUNT)
    fh.setLevel(logging.INFO)
    fh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(fh)
except Exception as e:
    logger.warning("Could not create file handler %s: %s", LOG_FILE, e)

app = Flask(__name__)

def write_pid(pid_path=PID_FILE):
    try:
        pid_dir = os.path.dirname(pid_path)
        if pid_dir and not os.path.exists(pid_dir):
            os.makedirs(pid_dir, exist_ok=True)
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
        return result != 0   # True if free (connect_ex != 0)
    except Exception:
        return False
    finally:
        s.close()

@app.route("/", methods=["GET", "POST"])
def receive():
    try:
        if request.method == "POST":
            payload = request.get_json(force=False, silent=True)
            if payload is None:
                text = request.get_data(as_text=True)
                logger.info("Received POST (non-JSON or empty). Raw data: %s", text[:200])
            else:
                logger.info("Received POST JSON (truncated to 200 chars): %s", str(payload)[:200])
            # respond quickly
            return jsonify({"status": "received", "time": datetime.utcnow().isoformat()}), 200
        else:
            return ("Webhook receiver running\n", 200)
    except Exception:
        logger.exception("Error handling request")
        return ("internal error\n", 500)

def startup_checks():
    logger.info("Starting startup checks...")
    logger.info("Python: %s", sys.version.replace("\n", " "))
    try:
        import flask
        logger.info("Flask version: %s", flask.__version__)
    except Exception as e:
        logger.exception("Flask import failed: %s", e)
        raise

    # Check port availability
    if not check_port_free(HOST, PORT):
        logger.error("Port %s:%s appears to be IN USE. Aborting startup.", HOST, PORT)
        raise SystemExit(1)
    logger.info("Port %s:%s is free.", HOST, PORT)

if __name__ == "__main__":
    try:
        startup_checks()
        write_pid()
        logger.info("Starting Flask webhook on http://%s:%s (use_reloader=False)", HOST, PORT)
        # IMPORTANT: use_reloader=False so process does not fork (systemd-friendly)
        # and threaded=False to avoid background worker threads interfering with logs
        app.run(host=HOST, port=PORT, debug=False, use_reloader=False)
    except SystemExit as e:
        logger.exception("Exiting due to SystemExit: %s", e)
        raise
    except Exception as e:
        logger.exception("Unhandled exception during startup: %s", e)
        # ensure non-zero exit code so systemd sees failure and can restart
        sys.exit(1)
