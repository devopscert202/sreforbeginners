# 📘 Site Reliability Engineering (SRE) Foundations  
*Expanded Training Manual (Instructor Notes + Learner Guide)*  

---

## 📑 Table of Contents  

1. **Introduction to SRE**  
   - What is SRE?  
   - Goals & Benefits  
   - Origins at Google  
   - SRE vs. DevOps  
   - Roles & Responsibilities  

2. **Core Concepts in SRE**  
   - Service Level Indicators (SLIs)  
   - Service Level Objectives (SLOs)  
   - Service Level Agreements (SLAs)  
   - Composite SLOs  
   - Practical Considerations  

3. **Error Budgeting**  
   - What is an Error Budget?  
   - Error Budget Calculation  
   - Benefits and Tradeoffs  
   - Example Scenarios  
   - Advanced Error Budget Policies  

4. **Monitoring & Observability**  
   - Monitoring vs. Observability  
   - The Three Pillars of Observability  
   - Golden Signals  
   - Monitoring & Observability Tools  
   - Alert Fatigue and How to Reduce It  
   - Correlating Observability Data  
   - AI/ML in Observability  

5. **Incident Management**  
   - What is an Incident?  
   - Goals of Incident Management  
   - Incident Lifecycle  
   - Severity Levels & Classification  
   - Blameless Postmortems  
   - Incident Communication  
   - Incident Metrics  
   - Automation in Incident Response  

6. **Toil Reduction**  
   - What is Toil?  
   - Characteristics & Disadvantages  
   - Strategies for Toil Reduction  
   - Automation Examples  

7. **SRE Culture**  
   - Principles of SRE Culture  
   - Shared Responsibility  
   - Learning from Failures  
   - Continuous Improvement  
   - Implementing SRE at Scale  

8. **Hands-On Labs (Practical Exercises)**  

9. **Knowledge Checks (Quizzes)**  

10. **Summary & Key Takeaways**  

---

## 📝 Lecture Notes  

### 1. Introduction to SRE  

**Definition:**  
SRE applies **software engineering** to IT operations. The core idea: treat **operations problems as software problems**.  

**Key Goals:**  
- Reduce manual work (toil).  
- Improve **reliability, scalability, and efficiency**.  
- Provide a measurable framework for system health.  

**Origins at Google:**  
- Created in **2003** by **Ben Treynor Sloss**.  
- Needed to run **planet-scale systems** like Search, Gmail, and Ads.  
- Introduced: error budgets, blameless postmortems, reduction of toil.  

**SRE vs. DevOps:**  
- **DevOps:** philosophy → break silos, improve collaboration.  
- **SRE:** concrete engineering discipline → measure reliability, apply automation.  

| Aspect          | DevOps (Culture)                | SRE (Discipline)                   |  
|-----------------|---------------------------------|-------------------------------------|  
| Goal            | Speed, collaboration            | Reliability, scalability            |  
| Practices       | CI/CD, pipelines, automation    | SLIs/SLOs, error budgets, postmortems|  
| Measurement     | Mostly qualitative              | Strict quantitative (SLIs/SLOs)     |  

**Roles in SRE Teams:**  
- **Reliability Engineer:** ensure service uptime.  
- **Incident Commander:** manages outages.  
- **Tooling Engineer:** builds automation.  
- **Observability Engineer:** enables monitoring and insights.  

---

### 2. Core Concepts in SRE  

**SLI (Service Level Indicator):**  
- *Definition:* Quantitative measure of system performance.  
- *Examples:*  
  - % of successful HTTP requests.  
  - p95 latency of API calls.  
  - Error rate < 0.01%.  

**SLO (Service Level Objective):**  
- *Definition:* Target value for an SLI over time.  
- *Example:* 99.9% success rate for checkout API over 30 days.  

**SLA (Service Level Agreement):**  
- *Definition:* External contract with customers.  
- *Example:* “We guarantee 99% uptime. If not, credits are issued.”  

**Composite SLOs:**  
- Aggregate multiple SLIs.  
- Example: Checkout service =  
  - Frontend latency < 200ms  
  - Payment API availability > 99.9%  
  - Error rate < 0.5%  

> **Trainer Note:** Common pitfall → Teams confuse **SLOs (internal)** with **SLAs (external contracts)**. Stress this difference.  

---

### 3. Error Budgeting  

**Concept:**  
- Every service has a reliability *target*.  
- The “budget” = allowable *unreliability*.  

**Formula:**  
```

Error Budget = 100% - SLO

```

**Example:**  
- SLO: 99.9% uptime  
- Error Budget = 0.1% downtime (~43 mins/month).  

**Benefits:**  
- Balances reliability vs innovation.  
- Gives business leaders a decision framework:  
  - If budget left → release new features.  
  - If budget exhausted → freeze releases, fix reliability.  

**Advanced Use:**  
- *Error Budget Policy*: Formal rules when budgets are consumed.  
- *Error Budget Burn Rates*: Track how quickly the budget is spent.  

---

### 4. Monitoring & Observability  

**Monitoring:**  
- Detects known failure conditions.  
- Example: “CPU > 90% for 5 min.”  

**Observability:**  
- Helps explain *unknown issues*.  
- Powered by **logs, metrics, traces**.  

**Golden Signals (must-monitor metrics):**  
1. **Latency** – how long requests take.  
2. **Traffic** – demand volume.  
3. **Errors** – failure rate.  
4. **Saturation** – resource usage limits.  

**Tools:**  
- **Prometheus + Grafana** (metrics & visualization).  
- **ELK/EFK stack** (logs).  
- **Jaeger, Zipkin, OpenTelemetry** (traces).  

**Alert Fatigue:**  
- Too many alerts → engineers ignore them.  
- Solutions:  
  - Tie alerts to **SLO violations**.  
  - Suppress noise.  
  - Automate escalations.  

**AI/ML in Observability:**  
- Detect anomalies before they cause outages.  
- Correlate cross-service failures.  
- Enable proactive incident response.  

---

### 5. Incident Management  

**What is an Incident?**  
Unplanned event disrupting a service.  

**Goals:**  
- Detect quickly.  
- Resolve fast.  
- Learn from it.  

**Incident Lifecycle:**  
1. **Preparation**  
2. **Detection & Analysis**  
3. **Mitigation**  
4. **Resolution**  
5. **Postmortem**  

**Severity Levels:**  
- Sev 1: Major outage, high customer/business impact.  
- Sev 2: Partial degradation.  
- Sev 3: Minor issue, low impact.  
- Sev 4: Cosmetic / informational.  

**Blameless Postmortems:**  
- Ask “*What happened?*” not “*Who caused it?*”.  
- Focus on process, not blame.  
- Document root cause, timeline, fixes, and prevention.  

**Metrics:**  
- **MTTD**: Mean Time to Detect.  
- **MTTA**: Mean Time to Acknowledge.  
- **MTTR**: Mean Time to Resolve.  
- **MTBF**: Mean Time Between Failures.  

**Automation Examples:**  
- Auto-healing services.  
- Auto traffic rerouting.  
- Auto-scaling.  

---

### 6. Toil Reduction  

**Definition:**  
Manual, repetitive, automatable tasks that don’t scale.  

**Characteristics:**  
- Repetitive  
- Manual  
- Automatable  
- No long-term value  

**Why reduce toil?**  
- Toil grows linearly with system size.  
- Prevents engineers from working on innovation.  

**Strategies:**  
- Automate everything possible.  
- Use IaC (Terraform, Ansible, etc.).  
- Implement self-healing services.  

---

### 7. SRE Culture  

**Principles:**  
- Reliability is a *feature*.  
- Failure is an opportunity to learn.  
- Shared responsibility between Dev & Ops.  
- Engineering-driven ops: “Ops work should look like code.”  

**Implementing SRE at Scale:**  
- Start with SLOs for critical services.  
- Establish error budgets.  
- Build automation first, not afterthought.  
- Make postmortems mandatory.  

---

## 🧪 Hands-On Labs  

1. **Create EC2 Instance** – basic infra setup for training.  
2. **Define SLIs/SLOs/SLAs for a Checkout Service** – practice reliability targets.  
3. **Error Budget Simulation** – simulate release decision trade-offs.  
4. **Prometheus + Grafana Setup** – implement Golden Signals.  
5. **Incident Simulation with Prometheus + Nginx** – detect/respond to failures.  
6. **Automated Toil Reduction with Shell + Cron** – build self-healing container.  

---

## ❓ Knowledge Checks (Quizzes)  

**Sample (from expanded bank):**  

**Q1:** Which is the correct order of incident lifecycle?  
- A) Detection → Mitigation → Preparation → Resolution  
- B) Preparation → Detection → Mitigation → Resolution → Postmortem ✅  
- C) Detection → Postmortem → Mitigation → Resolution  
- D) None of the above  

**Q2:** Error budget for an SLO of 99.95% uptime per month?  
- 30-day month → 0.05% downtime allowed → ~22 minutes. ✅  

**Q3:** Which Golden Signal is often the **earliest leading indicator** of a reliability issue?  
- A) Errors  
- B) Latency ✅  
- C) Traffic  
- D) Saturation  

---

## 🔑 Summary  

- **SRE is a mindset + engineering discipline.**  
- **SLIs/SLOs/SLAs** make reliability measurable.  
- **Error budgets** balance risk and innovation.  
- **Observability** enables deep system insights.  
- **Incident management** = minimize downtime + learn from failures.  
- **Toil reduction** frees teams to innovate.  
- **SRE culture** = shared responsibility, blamelessness, automation-first.  

---
