# 📘 Lesson 03: CI/CD, Chaos Engineering, and SRE Practices  

---

## 🧭 Table of Contents  
1. Introduction  
2. CI/CD in SRE  
   - CI/CD Fundamentals  
   - Benefits of CI/CD for Reliability  
   - CI/CD Pipeline Components  
   - CI/CD Tools  
   - Best Practices  
   - Metrics & KPIs  
   - Implementation Challenges  
   - GitOps for Infrastructure Automation  
   - Jenkins Pipelines in SRE  
   - GitHub Actions in SRE  
3. Chaos Engineering in SRE  
   - What It Is & Why It Matters  
   - Origins at Netflix (Chaos Monkey)  
   - Principles of Chaos Engineering  
   - Process & Experiment Design  
   - Tools for Chaos Engineering  
   - Chaos in Kubernetes  
   - Chaos Engineering Metrics  
   - Safety Practices & Pitfalls  
4. Performance Testing for Reliability  
   - What It Is & Key Aspects  
   - Types of Performance Tests  
   - Metrics (User & System Perspective)  
   - Tools & Process  
   - Realistic Load Profiles  
   - Performance Testing in CI/CD  
5. Integration into SRE Workflows  
   - How CI/CD Supports SRE Goals  
   - How Chaos Engineering Supports SRE Goals  
   - How Performance Testing Supports SRE Goals  
   - Integrated SRE Workflow  
   - Error Budgets & Continuous Improvement  
   - Building a Learning Culture  
6. SRE Team Structure, Metrics & Challenges  
   - Team Roles & Responsibilities  
   - SRE KPIs  
   - Common Implementation Challenges  
   - Future Trends  

---

## 1. Introduction  
This lesson explores how **CI/CD, Chaos Engineering, and Performance Testing** form the backbone of modern SRE practices.  
- CI/CD ensures **faster, safer deployments**.  
- Chaos Engineering validates **resilience under failure**.  
- Performance Testing proves the system can **scale and remain stable** under load.  
- Together, they create an **integrated reliability framework**.  

---

## 2. CI/CD in SRE  

### CI/CD Fundamentals  
- **CI (Continuous Integration):** frequently merging and testing code changes.  
- **CD (Continuous Delivery/Deployment):** automating build, test, and release.  
- Enables **frequent, reliable software delivery**.  

### Benefits for Reliability  
- Faster recovery (MTTR ↓).  
- Fewer deployment failures.  
- Easier rollbacks.  
- Enables feature velocity without compromising stability.  

### CI/CD Pipeline Components  
1. Source Code Repository (GitHub/GitLab).  
2. Build (compilation, packaging).  
3. Test (unit, integration, performance).  
4. Deployment (to staging/prod).  
5. Monitoring & rollback.  

### Tools  
- **CI:** Jenkins, GitHub Actions, GitLab CI, CircleCI, Azure DevOps.  
- **CD:** ArgoCD, Spinnaker, Flux, AWS CodeDeploy, Google Cloud Deploy.  
- **IaC + GitOps:** Terraform, Helm, Pulumi with Git as source of truth.  

### Best Practices  
- Automate everything (build → deploy).  
- Keep pipelines fast and deterministic.  
- Implement approval gates for prod.  
- Integrate tests (unit, integration, performance).  
- Rollback & safety checks: canary analysis, error budget checks.  

### Metrics & KPIs  
- **DORA Metrics:**  
  - Deployment frequency.  
  - Lead time for changes.  
  - Change failure rate.  
  - MTTR.  
- **Reliability Metrics:**  
  - Build success rate.  
  - Deployment success rate.  
  - Rollback frequency.  
  - Error budget consumption.  

### Implementation Challenges  
- Legacy/manual pipelines.  
- Cultural resistance.  
- Insufficient test coverage.  
- Complexity of multi-cloud/hybrid infra.  

### GitOps for Infrastructure Automation  
- Use Git as **single source of truth**.  
- Declarative configs + pull requests → auto-deploy with tools like ArgoCD.  
- **Benefits:** auditability, consistency, fast rollback.  

### Jenkins Pipelines in SRE  
- Declarative pipelines fit SRE needs:  
  - Version-controlled pipelines.  
  - Automated test + build + deploy.  
- **Pros:** mature, extensible, integrates with Docker/Kubernetes.  

### GitHub Actions in SRE  
- GitHub-native CI/CD.  
- Pros: tight repo integration, fast adoption.  
- Good for smaller teams & open-source projects.  

---

## 3. Chaos Engineering in SRE  

### What It Is  
- Discipline of **experimenting on systems** to build confidence in resilience.  
- Introduce controlled failures to surface weaknesses **before real incidents**.  

### Origins  
- Born at Netflix with **Chaos Monkey** (2011).  
- Expanded into the **Simian Army** (network latency, disk failures, etc.).  

### Principles of Chaos Engineering  
- Start small.  
- Define clear metrics (latency, error rate, availability).  
- Have abort switches.  
- Document everything.  
- Engage stakeholders.  

### Process  
1. Define steady state (baseline metrics).  
2. Form hypothesis (system survives instance failure).  
3. Inject failure (kill container, network loss).  
4. Observe results.  
5. Learn & improve.  

### Tools  
- **Docker-level:** Pumba.  
- **Kubernetes-level:** LitmusChaos, Chaos Mesh, Kube-Monkey, PowerfulSeal.  

### Chaos in Kubernetes  
- Test failures: pods, nodes, API server, network partitions, etc.  
- Benefits: validate complex distributed systems.  
- Risks: high blast radius if not scoped carefully.  

### Chaos Engineering Metrics  
- Experiment success/failure rate.  
- MTTR after chaos injection.  
- Error budget impact.  
- Developer confidence scores.  

### Safety Practices & Pitfalls  
- Safety first: run in non-prod → then limited prod.  
- Avoid: skipping hypothesis, inadequate monitoring, too much chaos at once, ignoring cultural acceptance.  

---

## 4. Performance Testing for Reliability  

### What It Is  
- Testing how system performs under **load, stress, and failures**.  
- Ensures systems can meet **SLOs at scale**.  

### Key Aspects  
- Throughput.  
- Latency / Response time.  
- Resource utilization.  
- Stability under stress.  
- Scalability.  

### Types of Tests  
- Load testing (expected traffic).  
- Stress testing (beyond normal limits).  
- Spike testing (sudden surges).  
- Endurance/soak testing.  
- Chaos testing (failures under load).  

### Metrics  
- User perspective: response time (avg, p95, p99).  
- System perspective: CPU, memory, disk I/O, network.  

### Tools & Process  
- Tools: Locust, JMeter, k6.  
- Process: plan → profile traffic → run tests → analyze → optimize.  

### Realistic Load Profiles  
- Must reflect real traffic patterns.  
- Data sources: analytics, logs, production monitoring.  
- Avoid oversimplified tests → false confidence.  

### Performance Testing in CI/CD  
- Integrate load/stress tests into pipelines.  
- Challenges: test runtime, environment parity.  
- Best practices: run lighter tests on PRs, full tests in staging/pre-prod.  

---

## 5. Integration into SRE Workflows  

- **CI/CD Supports SRE:** faster, safer releases with built-in rollbacks.  
- **Chaos Supports SRE:** turns unknown risks into known, manageable ones.  
- **Performance Testing Supports SRE:** validates scalability against SLOs.  

### Integrated Workflow  
1. Code merged → CI pipeline builds/tests.  
2. Deploy via CD with canary or blue-green.  
3. Chaos experiments validate resilience.  
4. Performance tests validate scale.  
5. Metrics feed into SLO monitoring + error budgets.  

### Error Budgets  
- Objective framework to balance reliability vs innovation.  
- Example: if 99.9% SLO = 0.1% downtime allowed.  
- Deploy features only if error budget not exhausted.  

### Building a Learning Culture  
- Incidents and chaos are **learning opportunities**.  
- Encourage blameless postmortems.  
- Share lessons across teams.  

---

## 6. SRE Team Structure, Metrics & Challenges  

### Team Roles & Responsibilities  
- SREs embed with dev teams.  
- Responsibilities: monitoring, automation, incident response, capacity planning, tooling.  

### SRE KPIs  
- Availability % (against SLO).  
- MTTR, MTTD.  
- Deployment frequency.  
- Automation coverage.  

### Common Challenges  
- Resistance to cultural change.  
- Alert fatigue.  
- Legacy systems.  
- Lack of observability.  

### Future Trends  
- **AI/ML for anomaly detection**.  
- **GitOps-first deployments**.  
- **Serverless reliability patterns**.  
- **Shift-left reliability** → earlier in dev lifecycle.  

---

# ✅ Summary  
Lesson 03 ties together **CI/CD, Chaos Engineering, and Performance Testing** as an integrated SRE practice.  
- CI/CD improves release reliability and velocity.  
- Chaos Engineering builds resilience via controlled failure.  
- Performance Testing validates scalability and SLO adherence.  
- Together, they support SRE’s mission: **reliability at scale with continuous learning**.  
