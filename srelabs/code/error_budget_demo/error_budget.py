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
