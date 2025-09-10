#!/usr/bin/env python3
"""
error_budget_interactive.py

Interactive error budget calculator and simulator for SRE training.

Usage:
  python3 error_budget_interactive.py
  (optional) python3 error_budget_interactive.py --simulate

This script:
 - Accepts SLO (percentage like 99.9 or fraction like 0.999),
 - Accepts window length in days (e.g., 30),
 - Accepts used downtime in minutes (or simulates outages),
 - Prints allowed downtime (error budget), remaining budget, burn %, and guidance.
"""

import sys
import argparse
import random

def parse_slo(inp: str):
    """Parse SLO input: accept percentages (e.g., '99.9') or fractions ('0.999')."""
    try:
        val = float(inp)
    except ValueError:
        raise ValueError("SLO must be a number (e.g. 99.9 or 0.999).")

    # Heuristic: if > 1 treat as percent
    if val > 1:
        slo_frac = val / 100.0
    else:
        slo_frac = val

    if not (0.0 < slo_frac < 1.0):
        raise ValueError("SLO must be between 0 and 1 (as fraction) or 0-100 (percent), and cannot be 0 or 1 exactly.")
    return slo_frac

def get_input(prompt, default=None, parser=float):
    """Prompt user with optional default and parse the response."""
    while True:
        raw = input(f"{prompt}" + (f" [{default}]" if default is not None else "") + ": ").strip()
        if raw == "" and default is not None:
            return default
        try:
            return parser(raw)
        except Exception as e:
            print(f"Invalid input: {e}. Try again.")

def format_minutes(minutes):
    """Return human-friendly minutes -> days/hours/minutes."""
    mins = int(round(minutes))
    days = mins // (24*60)
    hours = (mins % (24*60)) // 60
    mins_rem = mins % 60
    parts = []
    if days:
        parts.append(f"{days}d")
    if hours:
        parts.append(f"{hours}h")
    parts.append(f"{mins_rem}m")
    return " ".join(parts)

def main():
    parser = argparse.ArgumentParser(description="Interactive Error Budget Calculator")
    parser.add_argument("--simulate", action="store_true",
                        help="Simulate random outage events instead of manual used_downtime input.")
    args = parser.parse_args()

    print("\n== Error Budget Interactive Calculator (SRE Training) ==\n")

    # SLO
    while True:
        slo_raw = input("Enter SLO (percent or fraction). Examples: '99.9' or '0.999' [default 99.9]: ").strip()
        if slo_raw == "":
            slo_raw = "99.9"
        try:
            slo = parse_slo(slo_raw)
            break
        except Exception as e:
            print("Error:", e)

    # Window days
    while True:
        days_raw = input("Enter rolling window length in days [default 30]: ").strip()
        if days_raw == "":
            days = 30
            break
        try:
            days = int(days_raw)
            if days <= 0:
                raise ValueError("days must be > 0")
            break
        except Exception as e:
            print("Invalid days:", e)

    total_minutes = days * 24 * 60
    error_budget_minutes = (1 - slo) * total_minutes

    # used downtime input or simulation
    if args.simulate:
        # Simple simulation: generate N events with random durations
        print("\n-- Simulation mode selected --")
        while True:
            try:
                n_events = int(input("Number of outage events to simulate [default 5]: ") or "5")
                if n_events <= 0:
                    raise ValueError("Must be positive")
                break
            except Exception as e:
                print("Invalid:", e)
        # event durations random between 0.5 and 30 minutes
        events = [round(random.uniform(0.5, 30.0), 2) for _ in range(n_events)]
        used_downtime = sum(events)
        print(f"\nSimulated {n_events} events, durations (minutes): {events}")
    else:
        while True:
            try:
                ud_raw = input("Enter used downtime this window in minutes (e.g., 35) [default 0]: ").strip()
                if ud_raw == "":
                    used_downtime = 0.0
                    break
                used_downtime = float(ud_raw)
                if used_downtime < 0:
                    raise ValueError("Used downtime cannot be negative")
                break
            except Exception as e:
                print("Invalid input:", e)

    remaining = error_budget_minutes - used_downtime
    burn_percent = (used_downtime / error_budget_minutes * 100.0) if error_budget_minutes > 0 else float('inf')

    print("\n--- Error Budget Summary ---")
    print(f"SLO: {slo*100:.3f}% over last {days} days")
    print(f"Total time window: {total_minutes} minutes ({days} days)")
    print(f"Allowed downtime (Error Budget): {error_budget_minutes:.2f} minutes ({format_minutes(error_budget_minutes)})")
    print(f"Used downtime so far: {used_downtime:.2f} minutes ({format_minutes(used_downtime)})")
    if remaining >= 0:
        print(f"Remaining error budget: {remaining:.2f} minutes ({format_minutes(remaining)})")
    else:
        print(f"Overrun of error budget: {abs(remaining):.2f} minutes ({format_minutes(abs(remaining))})")

    print(f"Error budget burn: {burn_percent:.2f}%\n")

    # Advisory logic
    # Conservative thresholds for guidance:
    if error_budget_minutes == 0:
        print("⚠️ SLO is 100% — no allowed downtime. This is unrealistic; consider setting a realistic SLO.")
    else:
        # Burn rate guidance
        # If used_downtime < 50% => safe; 50-100% => cautious; >100% => stop releases
        if used_downtime < 0.5 * error_budget_minutes:
            print("✅ Guidance: Error budget healthy. Safe to proceed with regular releases.")
        elif used_downtime < error_budget_minutes:
            print("⚠️ Guidance: Error budget is being consumed. Consider reducing risky releases and prioritize reliability work.")
        else:
            print("⛔ Guidance: Error budget exhausted or exceeded. Pause feature releases; focus on remediation and reducing downtime.")

    # Extra: suggest per-day allowance
    per_day_allowance = error_budget_minutes / days
    print(f"\nPer-day allowed downtime (avg): {per_day_allowance:.2f} minutes/day ({format_minutes(per_day_allowance)})")

    print("\n--- End ---\n")

if __name__ == "__main__":
    main()

