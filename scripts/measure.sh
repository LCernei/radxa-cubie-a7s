#!/usr/bin/env bash
# Read-only temperature and clock sampler.
# Usage: measure.sh [samples] [interval-seconds] [ssh-target]
# Prints TSV; redirect it to keep it.
set -euo pipefail

samples=${1:-30}
interval=${2:-20}
target=${3:-radxa@radxa-cubie-a7s.local}

if ! [[ $samples =~ ^[0-9]+$ && $interval =~ ^[0-9]+$ ]]; then
  echo "usage: $0 [samples] [interval-seconds] [ssh-target]" >&2
  exit 2
fi

ssh -o BatchMode=yes -o ConnectTimeout=15 "$target" "bash -s -- $samples $interval" <<'REMOTE'
set -eu
samples=$1
interval=$2
freq=/sys/devices/system/cpu/cpufreq

# Look zones up by name, as their numbering can change between kernels.
zone() {
  local z
  for z in /sys/class/thermal/thermal_zone*; do
    if [ "$(cat "$z/type")" = "$1" ]; then
      echo "$z/temp"
      return
    fi
  done
  echo /dev/null
}
little=$(zone cpul_thermal_zone)
big=$(zone cpub_thermal_zone)
skin=$(zone skin_zone)

cpu_times() {
  read -r _ user nice system idle iowait irq softirq _ </proc/stat
  total=$((user + nice + system + idle + iowait + irq + softirq))
  idle_total=$((idle + iowait))
}

printf '# %s kernel=%s cpuidle=%s\n' "$(date -Is)" "$(uname -r)" \
  "$(cat /sys/devices/system/cpu/cpuidle/current_driver 2>/dev/null || echo none)"
printf 'uptime_s\tlittle_mC\tbig_mC\tskin_mC\tlittle_cap_kHz\tbig_cap_kHz\tbusy_pct\n'

cpu_times
for ((i = 0; i < samples; i++)); do
  last_total=$total
  last_idle=$idle_total
  sleep "$interval"
  cpu_times
  dt=$((total - last_total))
  busy=$((dt > 0 ? 1000 * (dt - idle_total + last_idle) / dt : 0))
  read -r up _ </proc/uptime
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%d.%d\n' "${up%.*}" \
    "$(cat "$little")" "$(cat "$big")" "$(cat "$skin")" \
    "$(cat "$freq/policy0/scaling_max_freq")" "$(cat "$freq/policy6/scaling_max_freq")" \
    $((busy / 10)) $((busy % 10))
done
REMOTE
