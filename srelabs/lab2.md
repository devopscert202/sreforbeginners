
# 🧪 Lab 02: Creating SLIs, SLOs, and SLAs for a Sample Service  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  
Defining **SLIs, SLOs, and SLAs** is the first step to making reliability measurable. As an SRE, you will use these definitions to drive monitoring, alerting, and error budgeting decisions.  

In this exercise, we will define SLIs, SLOs, and SLAs for a **sample e-commerce checkout service** and practice saving them into a documentation file.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Create a file to document SLIs, SLOs, and SLAs.  
- Write definitions of SLIs (Service Level Indicators).  
- Set realistic SLOs (Service Level Objectives).  
- Draft SLAs (Service Level Agreements).  

---

## 📋 Prerequisites  
- Access to an EC2 instance (from **Lab 01**).  
- Basic knowledge of Linux commands and a text editor (`nano`).  

---

## 🔨 Steps  

### Step 1: Create a Documentation File  
1. Open your EC2 terminal.  
2. Use the `nano` editor to create a new file:  
   ```bash
   nano checkout-service-slo.md



### Step 2: Define SLIs (Service Level Indicators)

Add the following content inside the file:


# Service Level Indicators (SLIs)

- **Availability:** Percentage of successful HTTP requests (status code 200/201).
- **Latency:** 95th percentile (p95) of checkout request latency should be < 300ms.
- **Error Rate:** Percentage of failed requests (4xx, 5xx) out of total requests.
- **Throughput:** Number of checkout requests processed per second.


💡 **Note:** SLIs are **raw measurements** that describe the system’s behavior.



### Step 3: Define SLOs (Service Level Objectives)

Continue adding the following to the file:


# Service Level Objectives (SLOs)

- Availability: 99.9% per 30-day rolling window.
- Latency: 95% of checkout requests complete in < 300 ms.
- Error Rate: ≤ 0.1% failed requests per month.
- Throughput: Service must handle 100 requests per second.


💡 SLOs are **targets for SLIs**. They must be **achievable but challenging**.



### Step 4: Define SLA (Service Level Agreement)

Now add SLA details to the file:


# Service Level Agreement (SLA)

- SLA Uptime: 99% uptime per calendar month.
- SLA Credit Policy: If uptime drops below 99%, customers will receive service credits.
```

⚠️ **Reminder:** SLA is **customer-facing**, while SLOs are **internal targets**.



### Step 5: Save and Exit the File

* Press **`CTRL + O`** → hit **Enter** to save.
* Press **`CTRL + X`** to exit `nano`.

Verify file contents:

```bash
cat checkout-service-slo.md
```



## 🧾 Testing & Validation

1. Confirm the file exists:

   ```bash
   ls -l checkout-service-slo.md
   ```

2. Check the contents again:

   ```bash
   cat checkout-service-slo.md
   ```

✅ Expected output should include sections for **SLIs, SLOs, and SLA** with the content written above.


## 📌 Further Learning (SRE Context)

* **SLIs** represent raw system measurements.
* **SLOs** translate SLIs into reliability targets for engineering.
* **SLAs** are legal or contractual commitments to customers.

🔑 These definitions are essential for:

* **Error Budgets** (coming up in Lab 03).
* **Monitoring and Alerting** design (Labs 4–6).
* **Incident Management** (Labs 5, 8, 9).

---

## ✅ Lab Completion

You have successfully:

* Created and saved a documentation file for SLIs, SLOs, and SLA.
* Differentiated between **indicators, objectives, and agreements**.

This forms the foundation for **error budgeting and monitoring practices** in the next labs.

```


