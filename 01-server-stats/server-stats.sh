#!/bin/bash
#
# server-stats.sh - Analyse basic server performance stats
# Usage: ./server-stats.sh
#
# Targets Linux with GNU coreutils + procps (/proc filesystem required).
# Not supported on macOS/BSD.

# Exit on error, undefined var, or failed pipe
set -euo pipefail

# ---------- Helper functions ----------

print_header() {
    echo ""
    echo "=============================================="
    echo "  $1"
    echo "=============================================="
}

# ---------- 1. CPU Usage ----------
# We sample /proc/stat twice and compute the delta to get real usage.
# This is more accurate than reading a single snapshot.
cpu_usage() {
    print_header "Total CPU Usage"

    # Read the first line of /proc/stat (aggregate CPU stats)
    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    idle1=$((idle + iowait))
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))

    sleep 1  # wait 1 second

    read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
    idle2=$((idle + iowait))
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    # Delta
    total_diff=$((total2 - total1))
    idle_diff=$((idle2 - idle1))

    usage=$(awk -v t="$total_diff" -v i="$idle_diff" 'BEGIN { printf "%.2f", (t - i) * 100 / t }')
    echo "CPU Usage: ${usage}%"
    echo "Idle:      $(awk -v i="$idle_diff" -v t="$total_diff" 'BEGIN { printf "%.2f", i * 100 / t }')%"
}

# ---------- 2. Memory Usage ----------
memory_usage() {
    print_header "Total Memory Usage (RAM)"

    # `free -m` gives output in MB; `-h` is human readable but harder to parse
    # Columns: $1=Mem: $2=total $3=used $4=free $5=shared $6=buff/cache $7=available
    total=$(free -m | awk '/^Mem:/ {print $2}')
    used=$(free -m | awk '/^Mem:/ {print $3}')
    free_mb=$(free -m | awk '/^Mem:/ {print $4}')
    available=$(free -m | awk '/^Mem:/ {print $7}')  # "available" is what you usually want

    pct=$(awk -v u="$used" -v t="$total" 'BEGIN { printf "%.2f", u * 100 / t }')

    echo "Total:      ${total} MB"
    echo "Used:       ${used} MB (${pct}%)"
    echo "Free:       ${free_mb} MB"
    echo "Available:  ${available} MB"

    # Also show swap. Guard: some systems print no Swap line at all.
    swap_total=$(free -m | awk '/^Swap:/ {print $2}')
    swap_total=${swap_total:-0}
    swap_used=$(free -m | awk '/^Swap:/ {print $3}')
    if [ "$swap_total" -gt 0 ]; then
        swap_pct=$(awk -v u="$swap_used" -v t="$swap_total" 'BEGIN { printf "%.2f", u * 100 / t }')
        echo ""
        echo "Swap Total: ${swap_total} MB"
        echo "Swap Used:  ${swap_used} MB (${swap_pct}%)"
    fi
}

# ---------- 3. Disk Usage ----------
disk_usage() {
    print_header "Total Disk Usage"

    # -h = human readable, --output lets us pick columns
    # -x excludes virtual filesystems that always look "full"
    df -h --output=source,size,used,avail,pcent,target -x tmpfs -x devtmpfs
}

# ---------- 4. Top 5 Processes by CPU ----------
top_cpu_processes() {
    print_header "Top 5 Processes by CPU Usage"

    # --sort=-%cpu, show header, then top 5 data rows
    ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6
}

# ---------- 5. Top 5 Processes by Memory ----------
top_mem_processes() {
    print_header "Top 5 Processes by Memory Usage"

    ps -eo pid,ppid,user,%cpu,%mem,comm --sort=-%mem | head -n 6
}

# ---------- 6. Extra system info ----------
extra_stats() {
    print_header "System Information"

    # OS version (works on most distros)
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        echo "OS:            ${PRETTY_NAME:-Unknown}"
    fi

    echo "Kernel:        $(uname -r)"
    echo "Architecture:  $(uname -m)"
    echo "Hostname:      $(hostname)"

    # Uptime (pretty format) and load average
    echo "Uptime:        $(uptime -p 2>/dev/null || uptime)"
    echo "Load Average:  $(awk '{print $1", "$2", "$3}' /proc/loadavg)  (1m, 5m, 15m)"

    echo ""
    echo "Logged-in users:"
    who 2>/dev/null || echo "  (none)"

    echo ""
    echo "Failed login attempts (last 5):"
    # Requires root on some distros to read auth.log / secure
    if [ -r /var/log/auth.log ]; then
        grep -i "failed password" /var/log/auth.log 2>/dev/null | tail -n 5 || echo "  (none)"
    elif [ -r /var/log/secure ]; then
        grep -i "failed password" /var/log/secure 2>/dev/null | tail -n 5 || echo "  (none)"
    else
        echo "  (auth log not readable — try running with sudo)"
    fi
}

# ---------- Main ----------

main() {
    echo "Server Performance Stats — $(date)"
    cpu_usage
    memory_usage
    disk_usage
    top_cpu_processes
    top_mem_processes
    extra_stats
}

main "$@"
