#!/usr/bin/env python3
"""
composite_slo_demo.py
Demo script for calculating SLOs, Error Budgets, and Composite SLO
for a retail application (frontend, payment API, backend, catalog).
"""

import re
import csv
import random

# Default configuration
DEFAULT_WINDOW_DAYS = 30
DEFAULT_SLOS = {
    "frontend": 99.95,
    "payment_api": 99.9,
    "backend": 99.9,
    "catalog": 99.8,
}

SERVICES = list(DEFAULT_SLOS.keys())


def parse_slo_input(raw: str):
    """Accepts 99.9, 99.9%, 0.999, or .999 -> returns (pct, frac)."""
    raw = raw.strip().replace("%", "")
    if not raw:
        return None
    try:
        num = float(raw)
    except ValueError:
        return None

    if 0 < num <= 1:  # fraction like 0.999
        return round(num * 100, 6), num
    elif 1 < num <= 100:  # percent like 99.9
        return num, round(num / 100, 6)
    else:
        return None


def format_minutes(minutes: float):
    """Convert minutes into days/hours/minutes string."""
    total = round(minutes)
    days, rem = divmod(total, 1440)
    hours, mins = divmod(rem, 60)
    parts = []
    if days > 0:
        parts.append(f"{days}d")
    if hours > 0:
        parts.append(f"{hours}h")
    parts.append(f"{mins}m")
    return " ".join(parts)


def main():
    print("\n🛒 Composite SLO Demo – Retail Application")
    print("Services:", ", ".join(SERVICES))
    print("This script will compute per-service SLOs, error budgets, and composite SLO.\n")

    # Time window
    try:
        window_days = int(input(f"Enter window length in days [{DEFAULT_WINDOW_DAYS}]: ") or DEFAULT_WINDOW_DAYS)
    except ValueError:
        window_days = DEFAULT_WINDOW_DAYS
    total_minutes = window_days * 24 * 60
    print(f"Using window: {window_days} days = {total_minutes} minutes\n")

    # Collect SLOs
    slos_pct = {}
    slos_frac = {}
    for svc in SERVICES:
        raw = input(f"Enter SLO for {svc} (percent or fraction) [default {DEFAULT_SLOS[svc]}%]: ") or str(
            DEFAULT_SLOS[svc]
        )
        parsed = parse_slo_input(raw)
        if not parsed:
            print(f"❌ Invalid SLO for {svc}: {raw}")
            return
        pct, frac = parsed
        slos_pct[svc] = pct
        slos_frac[svc] = frac

    print("\nConfigured SLOs:")
    for svc in SERVICES:
        print(f" - {svc:12s}: {slos_pct[svc]:6.3f}%   (fraction {slos_frac[svc]:.6f})")
    print()

    # Error budgets
    error_budget = {}
    for svc in SERVICES:
        error_budget[svc] = (1 - slos_frac[svc]) * total_minutes

    print(f"Per-service Error Budgets (over {window_days} days):")
    for svc in SERVICES:
        print(f" - {svc:12s}: {error_budget[svc]:10.2f} min (~{format_minutes(error_budget[svc])})")
    print()

    # Used downtime
    simulate = input("Simulate used downtime values? (y/N): ").lower().startswith("y")
    used_downtime = {}
    for svc in SERVICES:
        if simulate:
            used_downtime[svc] = round(random.uniform(0, error_budget[svc] * 1.5), 2)
        else:
            raw = input(f"Enter used downtime (minutes) for {svc} [0]: ") or "0"
            try:
                used_downtime[svc] = float(raw)
            except ValueError:
                used_downtime[svc] = 0.0

    print("\nBudget summary per service:")
    header = f"{'Service':12s} | {'Allowed(min)':>12s} | {'Used(min)':>10s} | {'Remaining(min)':>14s} | {'Burn%':>6s}"
    print(header)
    print("-" * len(header))
    for svc in SERVICES:
        allowed = error_budget[svc]
        used = used_downtime[svc]
        remaining = allowed - used
        burn = (used / allowed * 100) if allowed > 0 else float("inf")
        print(f"{svc:12s} | {allowed:12.2f} | {used:10.2f} | {remaining:14.2f} | {burn:6.2f}")

    # Composite SLO
    composite_frac = 1
    for svc in SERVICES:
        composite_frac *= slos_frac[svc]
    composite_pct = composite_frac * 100
    composite_allowed = (1 - composite_frac) * total_minutes

    print("\nComposite SLO (AND of all services):")
    print(f" - Composite SLO fraction : {composite_frac:.6f}")
    print(f" - Composite SLO percent  : {composite_pct:.4f}%")
    print(
        f" - Composite allowed downtime: {composite_allowed:.2f} min (~{format_minutes(composite_allowed)})\n"
    )

    print("💡 Teaching Notes:")
    print(" - Composite SLO = probability all services meet their targets.")
    print(" - More services => lower effective end-to-end reliability.")
    print(" - Composite error budget shows how tight reliability is for the full user journey.\n")

    # Save CSV
    with open("composite_slo_summary.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["service", "slo_pct", "slo_frac", "allowed_min", "used_min", "remaining_min", "burn_pct"])
        for svc in SERVICES:
            allowed = error_budget[svc]
            used = used_downtime[svc]
            remaining = allowed - used
            burn = (used / allowed * 100) if allowed > 0 else "INF"
            writer.writerow([svc, slos_pct[svc], slos_frac[svc], allowed, used, remaining, burn])
    print("📂 Results saved to composite_slo_summary.csv")


if __name__ == "__main__":
    main()

