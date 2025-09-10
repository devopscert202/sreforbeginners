#!/usr/bin/env bash
#
# composite_slo_demo_fixed.sh
#
# Robust demo script to compute per-service SLOs, error budgets, used downtime,
# remaining budgets, burn rates, and the composite SLO for a retail application.
#
# Services: frontend, payment_api, backend, catalog (modifiable)
#
# Usage:
#   ./composite_slo_demo_fixed.sh
#   ./composite_slo_demo_fixed.sh --simulate
#
set -euo pipefail

# ---------- Configuration ----------
WINDOW_DAYS_DEFAULT=30

declare -A DEFAULT_SLOS_PERCENT=(
  ["frontend"]=99.95
  ["payment_api"]=99.9
  ["backend"]=99.9
  ["catalog"]=99.8
)

SERVICES=("frontend" "payment_api" "backend" "catalog")

# ---------- Helpers ----------
bc_calc() { echo "$@" | bc -l 2>/dev/null || echo "0"; }

# sanitize numeric input: allow .5, 0.999, 99.9, 99.9%
is_number() {
  [[ $1 =~ ^[0-9]*\.?[0-9]+$ ]]
}

# format minutes to human friendly
format_minutes() {
  local mins_float="$1"
  # round to nearest integer minute
  local mins
  mins=$(printf "%.0f" "$mins_float")
  local days=$(( mins / (24*60) ))
  local hours=$(( (mins % (24*60)) / 60 ))
  local minutes=$(( mins % 60 ))
  local out=""
  (( days > 0 )) && out="${out}${days}d "
  (( hours > 0 )) && out="${out}${hours}h "
  out="${out}${minutes}m"
  echo "$out"
}

sep() { printf '%0.s-' $(seq 1 72); echo; }

# parse SLO input: accepts "99.9", "99.9%", "0.999", ".999"
# outputs two globals: PARSED_PCT (e.g. 99.9) and PARSED_FRAC (e.g. 0.999)
parse_slo_input() {
  local raw="$1"
  # Trim whitespace
  raw="${raw#"${raw%%[![:space:]]*}"}"
  raw="${raw%"${raw##*[![:space:]]}"}"
  # remove trailing % if present
  raw="${raw%\%}"

  if ! is_number "$raw"; then
    return 1
  fi

  # Convert to number using bc to detect >1 or <=1
  # Use scale high enough
  local num
  num=$(bc_calc "scale=8; $raw+0")
  # If input is <= 1 => treat as fraction (0.999)
  if awk "BEGIN {exit !($num <= 1)}"; then
    # fraction given
    # validate >0
    if awk "BEGIN {exit !($num > 0)}"; then
      PARSED_FRAC=$(printf "%.8f" "$num")
      # pct = frac * 100
      PARSED_PCT=$(bc_calc "scale=6; $PARSED_FRAC * 100")
      return 0
    else
      return 1
    fi
  else
    # treat as percent, e.g., 99.9
    if awk "BEGIN {exit !($num > 0 && $num <= 100)}"; then
      PARSED_PCT=$(printf "%.6f" "$num")
      PARSED_FRAC=$(bc_calc "scale=8; $PARSED_PCT / 100")
      return 0
    else
      return 1
    fi
  fi
}

# ---------- Argument parsing ----------
SIMULATE=0
if [[ "${1:-}" == "--simulate" ]]; then
  SIMULATE=1
fi

# ---------- Intro ----------
cat <<'INTRO'
Composite SLO Demo - Retail Application
Services: frontend, payment_api, backend, catalog
This script will:
 - Ask for SLO (%) for each service (or use defaults)
 - Compute per-service error budget (minutes) for a window (default 30 days)
 - Ask for used downtime (minutes) per service (or simulate)
 - Compute remaining budgets and burn %
 - Compute Composite SLO (product of service SLO fractions)
 - Show composite error budget and interpretation
INTRO

sep
read -r -p "Enter window length in days [${WINDOW_DAYS_DEFAULT}]: " WINDOW_DAYS_INPUT
WINDOW_DAYS_INPUT="${WINDOW_DAYS_INPUT:-$WINDOW_DAYS_DEFAULT}"
if ! [[ "$WINDOW_DAYS_INPUT" =~ ^[0-9]+$ ]] || (( WINDOW_DAYS_INPUT <= 0 )); then
  echo "Invalid days value. Must be positive integer." >&2
  exit 1
fi
WINDOW_DAYS="$WINDOW_DAYS_INPUT"
TOTAL_MINUTES=$(( WINDOW_DAYS * 24 * 60 ))
echo "Using window: ${WINDOW_DAYS} days -> ${TOTAL_MINUTES} minutes"
sep

# ---------- Collect SLOs ----------
declare -A SLOS_PCT
declare -A SLOS_FRAC
for svc in "${SERVICES[@]}"; do
  default_pct="${DEFAULT_SLOS_PERCENT[$svc]}"
  read -r -p "Enter SLO for ${svc} (percent or fraction) [default ${default_pct}%]: " input_raw
  input_raw="${input_raw:-$default_pct}"

  if ! parse_slo_input "$input_raw"; then
    echo "Invalid SLO value for ${svc}: '${input_raw}'. Expected forms: 99.9  or 99.9% or 0.999 or .999" >&2
    exit 1
  fi

  # PARSED_PCT and PARSED_FRAC are set by parse_slo_input
  SLOS_PCT[$svc]="$PARSED_PCT"
  SLOS_FRAC[$svc]="$PARSED_FRAC"
done

sep
echo "Configured SLOs:"
for svc in "${SERVICES[@]}"; do
  printf " - %-12s : %7s%%   (fraction: %s)\n" "$svc" "${SLOS_PCT[$svc]}" "${SLOS_FRAC[$svc]}"
done
sep

# ---------- Compute per-service error budgets ----------
declare -A ERROR_BUDGET_MIN
for svc in "${SERVICES[@]}"; do
  frac="${SLOS_FRAC[$svc]}"
  allowed=$(bc_calc "scale=6; (1 - $frac) * $TOTAL_MINUTES")
  # ensure non-negative (in case of rounding)
  if awk "BEGIN {exit !($allowed < 0)}"; then
    allowed="0"
  fi
  ERROR_BUDGET_MIN[$svc]="$allowed"
done

echo "Per-service Error Budgets (allowed downtime over ${WINDOW_DAYS} days):"
for svc in "${SERVICES[@]}"; do
  allowed="${ERROR_BUDGET_MIN[$svc]}"
  readable=$(format_minutes "$allowed")
  printf " - %-12s : %10.4f minutes  (~%10s)\n" "$svc" "$allowed" "$readable"
done
sep

# ---------- Used downtime ----------
declare -A USED_DOWNTIME_MIN
if (( SIMULATE )); then
  echo "SIMULATION MODE: Generating used downtimes for each service..."
  for svc in "${SERVICES[@]}"; do
    allowed="${ERROR_BUDGET_MIN[$svc]}"
    # choose upper bound: max(1, allowed * 1.5)
    upper=$(bc_calc "scale=4; if ($allowed <= 1) 1 else $allowed * 1.5")
    # random float in [0, upper)
    rand=$(awk -v u="$upper" 'BEGIN{srand(); printf("%.2f", rand()*u)}')
    USED_DOWNTIME_MIN[$svc]="$rand"
  done
else
  echo "Enter used downtime (in minutes) for each service (0 if none)."
  for svc in "${SERVICES[@]}"; do
    read -r -p "Used downtime for ${svc} in minutes [0]: " ud
    ud="${ud:-0}"
    if ! is_number "$ud"; then
      echo "Invalid used downtime number for ${svc}: '$ud'" >&2
      exit 1
    fi
    USED_DOWNTIME_MIN[$svc]="$ud"
  done
fi

sep
echo "Used downtime (minutes):"
for svc in "${SERVICES[@]}"; do
  printf " - %-12s : %8s minutes\n" "$svc" "${USED_DOWNTIME_MIN[$svc]}"
done
sep

# ---------- Compute remaining budgets, burn% ----------
echo "Budget summary per service:"
printf "Service       | Allowed(min)  | Used(min)   | Remaining(min)  | Burn(%%)\n"
printf "--------------+---------------+-------------+-----------------+---------\n"
for svc in "${SERVICES[@]}"; do
  allowed="${ERROR_BUDGET_MIN[$svc]}"
  used="${USED_DOWNTIME_MIN[$svc]}"
  remaining=$(bc_calc "scale=6; $allowed - $used")
  # burn percent = used / allowed * 100 ; handle allowed==0
  if awk "BEGIN {exit !($allowed > 0)}"; then
    burn_pct=$(bc_calc "scale=4; ($used / $allowed) * 100")
    # cap display
    burn_display=$(printf "%.2f" "$burn_pct")
  else
    burn_display="INF"
  fi
  printf "%-13s | %13.4f | %11.4f | %15.4f | %7s\n" \
    "$svc" "$allowed" "$used" "$remaining" "$burn_display"
done
sep

# ---------- Compute Composite SLO (AND) ----------
composite_frac="1"
for svc in "${SERVICES[@]}"; do
  composite_frac=$(bc_calc "scale=12; $composite_frac * ${SLOS_FRAC[$svc]}")
done
composite_pct=$(bc_calc "scale=6; $composite_frac * 100")
composite_allowed=$(bc_calc "scale=6; (1 - $composite_frac) * $TOTAL_MINUTES")
composite_readable=$(format_minutes "$composite_allowed")

echo "Composite SLO (AND of all services):"
printf " - Composite SLO fraction : %s\n" "$composite_frac"
printf " - Composite SLO percent  : %s%%\n" "$composite_pct"
printf " - Composite allowed downtime over %d days: %10.4f minutes (~%s)\n" "$WINDOW_DAYS" "$composite_allowed" "$composite_readable"
sep

# ---------- Interpretation guidance ----------
cat <<GUIDE
Interpretation / teaching notes:
 - Composite SLO represents the probability that ALL listed services meet their individual SLOs simultaneously.
 - Multiplying fractions reduces the effective end-to-end SLO (e.g., many 99.9% components -> lower composite).
 - Composite allowed downtime is the practical downtime tolerated for the whole end-to-end path.
 - If composite allowed downtime is very small, consider increasing redundancy, adding retries, or raising individual SLOs.
GUIDE
sep

# ---------- CSV output ----------
OUTCSV="composite_slo_summary.csv"
echo "service,slo_pct,slo_frac,allowed_min,used_min,remaining_min,burn_pct" > "$OUTCSV"
for svc in "${SERVICES[@]}"; do
  allowed="${ERROR_BUDGET_MIN[$svc]}"
  used="${USED_DOWNTIME_MIN[$svc]}"
  remaining=$(bc_calc "scale=6; $allowed - $used")
  if awk "BEGIN {exit !($allowed > 0)}"; then
    burn_pct=$(bc_calc "scale=6; ($used / $allowed) * 100")
  else
    burn_pct="INF"
  fi
  echo "${svc},${SLOS_PCT[$svc]},${SLOS_FRAC[$svc]},${allowed},${used},${remaining},${burn_pct}" >> "$OUTCSV"
done
echo "CSV summary written to: $OUTCSV"

echo
echo "Demo complete."

