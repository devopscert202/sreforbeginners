# 📘 SRE Foundations – Lab Workbook  

Welcome to the **Site Reliability Engineering (SRE) Foundations Lab Series**.  
This repo contains **14 hands-on labs** designed for freshers and professionals to practice key SRE concepts — from infrastructure setup, to SLIs/SLOs, error budgets, monitoring, incident management, toil reduction, chaos engineering, and CI/CD.  

Each lab builds on the previous ones, forming a complete training journey.  

---

## 📑 Lab Index  

| Lab No. | Title | Purpose / What You’ll Learn |
|---------|-------|------------------------------|
| [Lab 01](lab01.md) | Creating an EC2 Instance | Provision compute resources in AWS, configure networking & security, and connect via SSH. Foundation for all later labs. |
| [Lab 02](lab02.md) | Creating SLIs, SLOs, and SLAs | Define and document service reliability targets that form the basis for monitoring and error budgets. |
| [Lab 03](lab03.md) | Calculating and Simulating Error Budget | Calculate allowed downtime from SLOs and simulate trade-offs between reliability and feature velocity. |
| [Lab 04](lab04.md) | Setting up Prometheus and Grafana | Deploy open-source monitoring and visualization tools for system and application metrics. |
| [Lab 05](lab05.md) | Implementing Incident Management with Prometheus | Configure Prometheus to monitor services (Nginx) and detect outages for incident management. |
| [Lab 06](lab06.md) | Toil Reduction with Automated Service Recovery | Write a shell script with cron to automatically detect and restart failed services. |
| [Lab 07](lab07.md) | Blue-Green and Canary Deployment | Safely release new versions of applications using traffic-switching and canary rollout strategies. |
| [Lab 08](lab08.md) | Automating SRE with Ansible and HTTPS Nginx | Use Ansible playbooks to automate deployment of Nginx with self-signed SSL for secure configuration. |
| [Lab 09](lab09.md) | Monitoring EC2 + Alerting with Node Exporter & Alertmanager | Extend monitoring to system-level metrics and configure alerting rules for CPU/memory thresholds. |
| [Lab 10](lab10.md) | System Monitoring, Alerts, and Automated Response | Create Prometheus alert rules, integrate Alertmanager webhooks, and implement basic incident auto-response. |
| [Lab 11](lab11.md) | CI/CD Pipeline with Jenkins and Docker | Build a pipeline to automate Docker image builds and deployments using Jenkins declarative pipelines. |
| [Lab 12](lab12.md) | Chaos Engineering with Pumba | Inject controlled chaos (container crashes) to validate service resilience under random failures. |
| [Lab 13](lab13.md) | Multi-User Load Testing with Chaos | Use Locust to generate concurrent user load and combine with chaos injection to test system robustness. |
| [Lab 14](lab14.md) | Container Restart Detection & Alerting | Monitor Docker container restart counts, trigger alerts when thresholds are exceeded, and automate detection. |

---

## 🎯 How to Use This Repo  

1. Start with **Lab 01** and proceed sequentially.  
2. Each lab is self-contained in a `.md` file with:  
   - Introduction & Objectives  
   - Prerequisites  
   - Detailed Step-by-Step Instructions  
   - Testing & Validation steps  
   - Further Learning (SRE context)  
   - Completion checklist  
3. Commands, configs, and code snippets are provided in **ready-to-run format**.  

---

## 🛠️ Tools Used  

- **AWS EC2** (infrastructure)  
- **Prometheus + Grafana** (monitoring & visualization)  
- **Alertmanager** (alerting)  
- **Ansible** (automation)  
- **Docker & Docker Compose** (containerization)  
- **Jenkins** (CI/CD pipelines)  
- **Pumba** (chaos engineering)  
- **Locust** (load testing)  

---

## 📌 Why These Labs Matter  

- **Freshers**: Learn SRE fundamentals by doing.  
- **Practitioners**: Practice real-world reliability patterns.  
- **Organizations**: Train teams in SRE best practices across monitoring, automation, incident management, and reliability engineering.  

---

## ✅ Next Steps  

- Clone this repo and work through labs sequentially.  
- Use the labs to build your **SRE project portfolio**.  
- Adapt these exercises to real-world services by plugging in your own applications and monitoring systems.  

Happy Learning!
