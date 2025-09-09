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
