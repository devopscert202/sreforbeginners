# 🧪 Lab 01: Creating an EC2 Instance  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  
Provisioning compute resources on the cloud is a core SRE skill, as reliable services often depend on properly configured infrastructure.  
In this exercise, you will learn how to launch and connect to an **AWS EC2 instance**, which will serve as the base environment for subsequent labs such as monitoring, observability, incident response, and automation.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Launch an EC2 instance in AWS.  
- Configure key instance settings (AMI, instance type, security).  
- Connect securely to the instance using SSH or EC2 Instance Connect.  
- Validate that the instance is ready for use in later labs.  

---

## 📋 Prerequisites  
- An **AWS account** with administrator-level access.  
- Basic familiarity with the **AWS Management Console**.  
- SSH client installed (Linux/macOS Terminal, Windows PowerShell, or PuTTY).  

---

## 🔨 Steps  

### Step 1: Access EC2 Service  
1. Log in to the **AWS Management Console**.  
2. In the search bar, type **EC2** and navigate to the **EC2 Dashboard**.  

---

### Step 2: Launch a New Instance  
1. Click **Launch Instance**.  
2. Provide a name for your instance (e.g., `sre-lab-ec2`).  
3. Choose an **Amazon Machine Image (AMI)** → **Amazon Linux 2** (recommended).  

---

### Step 3: Select Instance Type  
1. For training purposes, choose **t2.micro** (eligible for AWS Free Tier).  
2. For production systems, sizing should be based on CPU, memory, and workload needs.  

---

### Step 4: Configure Instance Settings  
1. Set **Network** = default VPC.  
2. Enable **Auto-assign Public IP** (so you can SSH into the instance).  
3. (Optional) Add a **User Data script** to install packages on startup.  

**Example User Data script (installs Apache):**  
```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
````

---

### Step 5: Configure Storage

* Accept the default **8 GiB** storage unless additional space is needed.

---

### Step 6: Configure Security Group

1. Create a new **Security Group**.
2. Add inbound rules:

   * **SSH (22)** → Source: My IP (restrict access for security).
   * **HTTP (80)** (optional, if testing web apps).

**⚠️ Best Practice:** Never allow SSH from **0.0.0.0/0** in production environments.

---

### Step 7: Key Pair Creation

1. Create or select an existing key pair.
2. Download the `.pem` file to your local machine.
3. Set appropriate permissions:

   ```bash
   chmod 400 mykey.pem
   ```

---

### Step 8: Launch the Instance

* Click **Launch Instance**.
* Wait until the instance state changes to **Running**.

---

### Step 9: Connect to Your Instance

Two connection methods:

* **Browser-based (EC2 Instance Connect):**

  1. Select your instance → Click **Connect**.
  2. Choose **EC2 Instance Connect** → Click **Connect**.

* **SSH Client (recommended for labs):**

  ```bash
  ssh -i mykey.pem ec2-user@<public-ip>
  ```

---

## 🧾 Validation

Run basic checks once logged in:

```bash
whoami
hostname
uptime
```

Expected results:

* User = `ec2-user`
* Hostname = instance ID
* Uptime = time since launch

---

## 📌 Further Learning (SRE Context)

This lab lays the foundation for **infrastructure reliability** in SRE:

* Reliable services begin with properly configured compute environments.
* Later labs will build on this instance to demonstrate:

  * **Monitoring & Observability** (Prometheus, Grafana).
  * **Incident Management** (alerts, simulations).
  * **Toil Reduction** (automated recovery scripts).
* AWS EC2 is a practical platform for simulating **real-world reliability challenges** faced by SRE teams.

---

## ✅ Lab Completion

You have successfully:

* Launched an EC2 instance.
* Configured networking, security, and authentication.
* Connected to the instance via browser or SSH.

This EC2 instance will be reused in future labs as the foundation for SRE practices.


