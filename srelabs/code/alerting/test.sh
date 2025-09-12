#!/usr/bin/env bash
# test.sh - lightweight traffic generator and demo helper to stop nginx and observe alerts.
set -euo pipefail

PRIVATE_IP=$(hostname -I | awk '{print $1}')
if [ -z "$PRIVATE_IP" ]; then PRIVATE_IP="127.0.0.1"; fi

# Parameters
REQS=200
CONC=10

echo "This script will generate HTTP requests to http://${PRIVATE_IP} and optionally stop nginx to trigger alerts."
echo "Press ENTER to start traffic generator, or CTRL-C to cancel."
read -r

echoinfo(){ printf "\n[INFO] %s\n" "$*"; }

# Simple background traffic generator using xargs for lightweight parallelism
# loops REQS times and does CONC requests in parallel batches
echoinfo "Generating ${REQS} requests to http://${PRIVATE_IP} with concurrency ${CONC}..."
seq "${REQS}" | xargs -n1 -P"${CONC}" -I{} curl -s "http://${PRIVATE_IP}/" >/dev/null 2>&1 || true
echoinfo "Traffic generation completed."

echo
echo "Now you can stop nginx to trigger an alert."
read -p "Type 's' and press ENTER to stop nginx now (or just press ENTER to skip): " ans
if [ "${ans}" = "s" ]; then
  sudo systemctl stop nginx
  echoinfo "nginx stopped. Wait ~10-30s and check Prometheus Alerts and Alertmanager UI."
  echo "To restore, run: sudo systemctl start nginx"
else
  echoinfo "Skipping nginx stop."
fi

echo "Test script complete."

