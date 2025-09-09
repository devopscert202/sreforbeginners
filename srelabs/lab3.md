
# 🧪 Lab 03: Calculating and Simulating Error Budget  

---

## 📘 Introduction  
This lab is part of the **Site Reliability Engineering (SRE) Foundations Training**.  
In SRE, an **error budget** is the maximum allowable amount of unreliability a service can have before reliability work takes priority over feature velocity.  

In this lab, you will:  
- Calculate error budgets from SLOs.  
- Simulate usage of error budgets with a Python script.  
- Observe how **burning through the error budget** affects release decisions.  

---

## 🎯 Objective  
By the end of this lab, you will be able to:  
- Calculate an error budget based on an SLO.  
- Write and run a Python script to simulate outages.  
- Decide whether to release new features or pause for reliability work based on the error budget.  

---

## 📋 Prerequisites  
- AWS EC2 instance (from **Lab 01**).  
- Python 3 installed (Amazon Linux 2 includes Python3 by default).  
- Completion of **Lab 02** (SLIs, SLOs, SLAs).  

---

## 🔨 Steps  

### Step 1: Navigate to the Home Directory  
```bash
cd ~
````

---

### Step 2: Create the Error Budget Simulation Script

Open a new Python file:

```bash
nano error_budget.py
```

Paste the following code inside:

```python
# error_budget.py
# Simple script to calculate error budget and simulate outages.

# Define SLO (Service Level Objective) in percentage
slo = 99.9  

# Total minutes in a 30-day month
total_time = 30 * 24 * 60  

# Allowed downtime = Error Budget
allowed_downtime = (100 - slo) / 100 * total_time  

# Example: used downtime this month (in minutes)
used_downtime = 35  

print(f"SLO: {slo}%")
print(f"Total time in 30 days: {total_time} minutes")
print(f"Allowed downtime (Error Budget): {allowed_downtime:.2f} minutes")
print(f"Used downtime so far: {used_downtime} minutes")

# Decision logic
if used_downtime < allowed_downtime:
    print("✅ Safe to release new features.")
else:
    print("⚠️ Error budget exhausted! Focus on reliability improvements.")
```

Save and exit:

* Press **CTRL+O**, Enter
* Press **CTRL+X**

---

### Step 3: Run the Script

```bash
python3 error_budget.py
```

---

## 🧾 Testing & Validation

### Test Case 1: Within Error Budget

* Set `used_downtime = 35` (as in code above).
* Run the script.

✅ Expected Output:

```
SLO: 99.9%
Total time in 30 days: 43200 minutes
Allowed downtime (Error Budget): 43.20 minutes
Used downtime so far: 35 minutes
✅ Safe to release new features.
```

---

### Test Case 2: Exceed Error Budget

Edit the script:

```bash
nano error_budget.py
```

Change:

```python
used_downtime = 60
```

Run again:

```bash
python3 error_budget.py
```

✅ Expected Output:

```
SLO: 99.9%
Total time in 30 days: 43200 minutes
Allowed downtime (Error Budget): 43.20 minutes
Used downtime so far: 60 minutes
⚠️ Error budget exhausted! Focus on reliability improvements.
```

---

### Test Case 3: Different SLO

Try changing:

```python
slo = 99.95
```

Run script:

```bash
python3 error_budget.py
```

✅ Expected Output:

```
SLO: 99.95%
Total time in 30 days: 43200 minutes
Allowed downtime (Error Budget): 21.60 minutes
Used downtime so far: 35 minutes
⚠️ Error budget exhausted! Focus on reliability improvements.
```

---

## 📌 Further Learning (SRE Context)

* **Error Budget Formula:**

  ```
  Error Budget = 100% - SLO
  ```
* Error budgets prevent over-engineering.
* They help balance:

  * **Innovation velocity** (shipping features).
  * **Reliability** (maintaining user trust).
* Common SRE practice:

  * If error budget is **healthy** → prioritize features.
  * If error budget is **burned** → freeze features, improve reliability.

---

## ✅ Lab Completion

You have successfully:

* Calculated error budgets from SLOs.
* Simulated error budget usage with Python.
* Learned how SRE teams use error budgets to make release decisions.

This prepares you for **monitoring and alerting** in the next labs.



