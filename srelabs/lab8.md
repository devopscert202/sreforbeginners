## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  

Automation is a cornerstone of SRE — it reduces toil, ensures consistency, and minimizes manual errors. **Ansible** is a powerful configuration management tool that lets SREs automate deployment and configuration tasks across systems.  

In this lab, you will use **Ansible** to install and configure **Nginx with HTTPS** on an EC2 instance.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Install and configure Ansible on your control node (EC2 instance).  
- Write an Ansible inventory file.  
- Create and run a playbook to deploy Nginx.  
- Enable HTTPS with a self-signed SSL certificate.  

---

## 📋 Prerequisites  
- An EC2 instance running Amazon Linux 2 (from **Lab 01**).  
- Docker not required here.  
- SSH key pair available to connect to localhost or other nodes.  
- Security group inbound rules: open ports **22 (SSH)**, **80 (HTTP)**, and **443 (HTTPS)**.  

---

## 🔨 Steps  

### Step 1: Install Ansible  
On Amazon Linux 2:  
```bash
sudo amazon-linux-extras enable ansible2
sudo yum install -y ansible
````

Verify installation:

```bash
ansible --version
```

---

### Step 2: Create Ansible Inventory

Create working directory:

```bash
mkdir ~/ansible-sre
cd ~/ansible-sre
```

Create inventory file:

```bash
nano hosts.ini
```

Paste:

```ini
[webservers]
localhost ansible_connection=local
```

Save and exit.

---

### Step 3: Create Ansible Playbook for Nginx with HTTPS

```bash
nano nginx-https.yml
```

Paste the following playbook:

```yaml
---
- name: Install and Configure Nginx with HTTPS
  hosts: webservers
  become: yes
  tasks:
    - name: Install Nginx and OpenSSL
      yum:
        name:
          - nginx
          - openssl
        state: present

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Create SSL directory
      file:
        path: /etc/nginx/ssl
        state: directory
        mode: '0755'

    - name: Generate self-signed SSL certificate
      command: >
        openssl req -x509 -nodes -days 365
        -newkey rsa:2048
        -keyout /etc/nginx/ssl/nginx.key
        -out /etc/nginx/ssl/nginx.crt
        -subj "/C=US/ST=CA/L=SanFrancisco/O=SRETraining/OU=DevOps/CN=localhost"
      args:
        creates: /etc/nginx/ssl/nginx.crt

    - name: Configure Nginx for HTTPS
      copy:
        dest: /etc/nginx/conf.d/ssl.conf
        content: |
          server {
              listen 443 ssl;
              server_name localhost;

              ssl_certificate /etc/nginx/ssl/nginx.crt;
              ssl_certificate_key /etc/nginx/ssl/nginx.key;

              location / {
                  root /usr/share/nginx/html;
                  index index.html;
              }
          }

          server {
              listen 80;
              server_name localhost;
              return 301 https://$host$request_uri;
          }

    - name: Reload Nginx
      service:
        name: nginx
        state: reloaded
```

Save and exit.

---

### Step 4: Run the Playbook

```bash
ansible-playbook -i hosts.ini nginx-https.yml
```

✅ Expected: All tasks run successfully without errors.

---

### Step 5: Verify Nginx HTTPS

Check that Nginx is listening on 443:

```bash
sudo ss -tulnp | grep nginx
```

Open in browser:

```
https://<EC2_PUBLIC_IP>
```

Accept the self-signed certificate warning.

✅ Expected: Default Nginx welcome page served over HTTPS.

---

## 🧾 Testing & Validation

1. **Ansible Playbook Syntax Check:**

   ```bash
   ansible-playbook --syntax-check nginx-https.yml
   ```

   ✅ Expected: “Playbook syntax is fine”.

2. **Playbook Execution:**

   ```bash
   ansible-playbook -i hosts.ini nginx-https.yml
   ```

   ✅ Expected: Tasks run successfully, Nginx installed and started.

3. **Verify HTTPS Port:**

   ```bash
   sudo ss -tulnp | grep :443
   ```

   ✅ Expected: Nginx process listening on port 443.

4. **Browser Test:**
   Visit `https://<EC2_PUBLIC_IP>` → Accept certificate warning → Nginx welcome page appears.

---

## 📌 Further Learning (SRE Context)

* **Automation reduces toil**: Instead of manually installing and configuring Nginx, one command (`ansible-playbook`) automates everything.
* **Idempotency**: Running the playbook multiple times will not break configuration — a key SRE principle.
* **Security by default**: Adding HTTPS ensures secure communication. In production, you’d use a trusted CA (e.g., Let’s Encrypt) instead of self-signed certs.
* **Scalability**: With Ansible, you can scale the same configuration to dozens of servers consistently.

---

## ✅ Lab Completion

You have successfully:

* Installed Ansible.
* Wrote an inventory and playbook.
* Automated Nginx deployment with HTTPS.
* Validated HTTPS service on your EC2 instance.

This lab demonstrates how **automation improves reliability and reduces toil** in SRE practices.




