# 🚀 Site Reliability Engineering (SRE) Course

This repository contains learning materials, examples, and hands-on exercises for a complete **Site Reliability Engineering (SRE)** training program.  
It introduces the principles, practices, and tools that help teams build and operate **highly reliable, scalable, and efficient systems**.

---

## 📖 Course Overview

SRE applies **software engineering principles to IT operations**.  
Originally pioneered at Google in 2003, SRE practices now help organizations worldwide deliver reliable services while balancing innovation and operational stability.

This course covers **foundational concepts, automation, alerting, CI/CD, chaos engineering, and advanced SRE practices**.  
Each lesson combines **theory + hands-on labs** to reinforce learning.

---

## 🧩 Modules & Topics

### **Lesson 01 – SRE Foundations**
- What is SRE? History, origin at Google  
- SRE vs. DevOps  
- Roles within an SRE team  
- **SLIs, SLOs, SLAs** – definitions, differences, and examples  
- Error budgeting (formula, usage, decision-making)  
- Monitoring vs. Observability  
  - Three pillars: Logs, Metrics, Traces  
  - Golden Signals  
  - Alert fatigue and solutions  
  - AI/ML in observability  
- Incident management  
  - Incident lifecycle & severity levels  
  - Blameless postmortems  
  - Incident communication (internal & external)  
  - Key metrics (MTTD, MTTA, MTTR, MTBF)  
- Toil reduction through automation  
- SRE cultural principles  

🔧 **Hands-On Labs**  
- Launch an EC2 instance in AWS  
- Document SLIs, SLOs, SLAs for a sample service  
- Error budget calculator & simulation  
- Prometheus + Grafana monitoring stack  
- Incident management with Prometheus & Nginx  
- Automating Nginx recovery with shell scripting + cron  

---

### **Lesson 02 – Automation, Alerting & Reliability Engineering**
- Principles of **Reliability Engineering**  
  - Automate everything  
  - Define measurable SLOs  
  - Implement error budgets  
  - Robust incident management  
  - Foster blameless culture  
  - Simplicity & continuous improvement  
- System design for reliability:  
  - Fault tolerance, graceful degradation, retry mechanisms  
- **Deployment strategies:** Blue-Green & Canary  
- **Automation in SRE**  
  - Infrastructure as Code (IaC) – Terraform, Ansible, CloudFormation  
  - Configuration management best practices  
  - CI/CD pipeline automation  
  - Monitoring & alerting automation (Prometheus, Alertmanager, PagerDuty)  
  - Incident response automation  
  - Self-service automation for developers  
- **Alerting in SRE**  
  - Principles of good alerting  
  - Avoiding alert fatigue  
  - Actionable vs. non-actionable alerts  
  - Alert prioritization framework (P0–P4)  
  - SLO-based alerting  
- **Incident response & postmortems**  
  - Incident commander role  
  - RCA techniques: 5 Whys, Fishbone, Fault Tree, Timeline analysis  
  - Blameless postmortems & continuous improvement  
- **Reliability cycle**: Design → Automate → Monitor → Respond → Improve  
- KPIs for reliability (availability, MTTR, automation coverage, etc.)  
- Common pitfalls (manual ops, blame culture, alert overload)  
- Future trends: AI-powered reliability, advanced observability, serverless resilience  

🔧 **Hands-On Labs**  
- HTTPS-enabled Nginx with Ansible automation  
- Prometheus + Alertmanager monitoring and alerting on EC2  
- Blue-Green & Canary deployment strategies  
- RCA exercise with real-world scenarios  

---

### **Lesson 03 – CI/CD, Chaos Engineering & SRE Practices**
- **CI/CD Fundamentals**  
  - Continuous Integration (CI) & Continuous Delivery/Deployment (CD)  
  - Pipeline components & best practices  
  - CI/CD metrics: Deployment frequency, MTTR, failure rate, error budget consumption  
  - Tooling: Jenkins, GitHub Actions, ArgoCD, GitOps  
- **Chaos Engineering**  
  - Principles and origins (Netflix Chaos Monkey)  
  - Chaos experiments: failure injection, network faults, resource constraints  
  - Chaos engineering process & safety practices  
  - Chaos engineering in Kubernetes (LitmusChaos, Chaos Mesh, Kube-Monkey)  
  - Chaos engineering pitfalls to avoid  
- **Performance Testing**  
  - Load, stress, spike, and capacity testing  
  - Key metrics: throughput, latency, resource utilization, scalability  
  - Performance testing in CI/CD pipelines  
  - Realistic load profiles & challenges in integration  
- **Integrated SRE Workflow**  
  - CI/CD → Chaos Engineering → Performance Testing → Continuous Improvement  
  - Error budgets as a unifying principle  
  - Learning culture and blamelessness  
- **Maturity Model for SRE Adoption**  
  - From manual operations → CI/CD → Chaos testing → Full reliability culture  

🔧 **Hands-On Labs**  
- Jenkins + Docker CI/CD pipeline for Flask app  
- Chaos experiments with Pumba on Docker/Kubernetes  
- Multi-user load testing with Locust under chaos conditions  
- Container restart detection & alerting  

---

## 🛠️ Hands-On Labs Overview

| Module | Lab |
|--------|-----|
| Lesson 01 | AWS EC2 Setup · SLIs/SLOs/SLAs · Error Budget Simulator · Prometheus & Grafana · Incident Simulation · Toil Reduction Script |
| Lesson 02 | HTTPS Nginx with Ansible · Prometheus + Alertmanager · Blue-Green & Canary Deployment · RCA Workshop |
| Lesson 03 | Jenkins CI/CD Pipeline · Chaos Engineering with Pumba · Load Testing with Locust · Container Restart Detection & Alerting |

---

## 🎯 Learning Outcomes

By completing this course, you will be able to:
- Apply **SRE principles** to build scalable, reliable systems  
- Define and measure **SLIs, SLOs, SLAs**  
- Use **error budgets** to balance innovation with reliability  
- Implement **automation, IaC, and configuration management**  
- Build **CI/CD pipelines** with integrated performance testing  
- Design and execute **chaos experiments** safely  
- Respond to incidents effectively and conduct **blameless postmortems**  
- Foster a **culture of reliability and continuous improvement**  

---

## 📚 References
- [Google SRE Book](https://sre.google/sre-book/table-of-contents/)  
- [The Site Reliability Workbook](https://sre.google/workbook/table-of-contents/)  
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)  
- [Grafana Documentation](https://grafana.com/docs/)  
- [Chaos Engineering at Netflix](https://netflixtechblog.com/tagged/chaos-engineering)  

---

## 🙌 Acknowledgments
This course is inspired by **real-world SRE practices** pioneered at Google, Netflix, and other industry leaders, and adapted for hands-on learning.
```

---

