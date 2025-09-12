# Lab: System Monitoring, Incident Alerts & Response with Prometheus and Alertmanager

## Objective
In this lab, you will:
- Set up **Prometheus**, **Node Exporter**, **Nginx Prometheus Exporter**, and **Alertmanager** on a single EC2 instance.  
- Configure Prometheus alert rules to detect when **Nginx goes down**.  
- Use **Alertmanager** to trigger notifications (via a local webhook receiver).  
- Simulate a failure by stopping Nginx and observe alerts firing.  

---

## Prerequisites
- **EC2 instance** (Amazon Linux 2 or Ubuntu recommended).  
- **Security Group inbound rules** open for ports:
  - 22 (SSH), 80 (Nginx), 9090 (Prometheus), 9093 (Alertmanager), 9100 (Node Exporter), 9113 (Nginx Exporter).  
- SSH access with `ec2-user` or similar account.  
- Internet access from EC2 instance (to download binaries).  
- `setup.sh` and `test.sh` copied to the instance (`scp` or git clone).  

---

## Steps

### 1. Connect to EC2
```bash
ssh -i /path/to/key.pem ec2-user@<EC2_PUBLIC_IP>
````

### 2. Upload Lab Files

Copy your prepared lab files (`setup.sh`, `test.sh`, `webhook_server.py`) to the instance:

```bash
scp -i /path/to/key.pem setup.sh test.sh webhook_server.py ec2-user@<EC2_PUBLIC_IP>:/home/ec2-user/
```

### 3. Run Setup Script

Make scripts executable and run setup:

```bash
chmod +x setup.sh test.sh
sudo ./setup.sh
```

The script installs Prometheus, Alertmanager, exporters, and starts them with `systemd`.

### 4. Validate Services

Check that services are running:

```bash
sudo systemctl status prometheus alertmanager node_exporter nginx-prometheus-exporter nginx webhook
```

Open in browser:

* Prometheus targets: `http://<EC2_PUBLIC_IP>:9090/targets`
* Prometheus alerts: `http://<EC2_PUBLIC_IP>:9090/alerts`
* Alertmanager UI: `http://<EC2_PUBLIC_IP>:9093`

You should see:

* `node_exporter` and `nginx` targets listed as **UP** in Prometheus targets page.

### 5. Run Test Script

Run:

```bash
./test.sh
```

It will:

* Generate HTTP traffic to `http://localhost` (via curl).
* Ask if you want to stop Nginx.

  * Press `s` and **Enter** to stop Nginx.
  * Otherwise, skip and keep nginx running.

### 6. Observe Alerts

When Nginx stops:

* Prometheus rule `up{job="nginx"} == 0` becomes true.
* After \~10 seconds, Prometheus **fires an alert `NginxDown`**.
* Alertmanager receives the alert and shows it in its UI.
* The webhook receiver logs the alert (check logs via `journalctl -u webhook -f`).

---

## Cleanup

Stop all services if you want to reset:

```bash
sudo systemctl stop prometheus alertmanager node_exporter nginx-prometheus-exporter webhook nginx
```

To remove all installed components:

```bash
sudo rm -rf /etc/prometheus /etc/alertmanager /var/lib/prometheus /var/lib/alertmanager /usr/local/bin/{prometheus,promtool,alertmanager,amtool,nginx-prometheus-exporter,node_exporter,webhook_server.py}
sudo userdel prometheus || true
sudo userdel nodeexp || true
```

---

## What to Observe

1. **Prometheus UI**

   * `http://<EC2_PUBLIC_IP>:9090/targets` → see `node_exporter` and `nginx` jobs UP.
   * `http://<EC2_PUBLIC_IP>:9090/alerts` → see `NginxDown` alert fire when Nginx is stopped.

2. **Alertmanager UI**

   * `http://<EC2_PUBLIC_IP>:9093` → shows `NginxDown` under active alerts.

3. **Webhook Receiver Logs**

   * Alerts are delivered to the local Flask webhook.
   * View logs:

     ```bash
     journalctl -u webhook -f
     ```

4. **Resolution**

   * Restart Nginx:

     ```bash
     sudo systemctl start nginx
     ```
   * The alert resolves in Prometheus & Alertmanager.

---

