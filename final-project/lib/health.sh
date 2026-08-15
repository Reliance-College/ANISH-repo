#!/usr/bin/env bash
#
# lib/health.sh — system health report for the System Admin Toolkit.
# SOURCED by sysadmin-toolkit.sh. Relies on helpers from lib/common.sh.
# Concepts: command substitution (L7), arithmetic (L6), conditionals (L8),
#           text processing (L23), here-docs (L19).
# -----------------------------------------------------------------------------

# health_disk : show disk usage and warn on partitions above a threshold.
health_disk() {
    local threshold="${DISK_WARN_PCT:-80}"
    header "Disk Usage (warn above ${threshold}%)"
    # df -hP = human-readable, POSIX format (stable columns). Skip the header.
    df -hP | awk 'NR==1 || $1 !~ /tmpfs|udev|loop/'
    echo
    # Check each real filesystem's use% against the threshold.
    df -hP | awk 'NR>1 && $1 !~ /tmpfs|udev|loop/ { gsub("%","",$5); print $5, $6 }' \
    | while read -r pct mount; do
        if [[ "$pct" -ge "$threshold" ]]; then
            log_warn "Disk ${mount} is at ${pct}% (>= ${threshold}%)"
        fi
    done
}

# health_memory : show memory usage.
health_memory() {
    header "Memory"
    if command -v free >/dev/null 2>&1; then
        free -h
        # Compute used percentage from 'free' (total vs available).
        local total used pct
        total=$(free | awk '/^Mem:/ { print $2 }')
        used=$(free | awk '/^Mem:/ { print $3 }')
        if [[ -n "$total" && "$total" -gt 0 ]]; then
            pct=$(( used * 100 / total ))
            echo
            echo "Memory used: ${pct}%"
            [[ "$pct" -ge "${MEM_WARN_PCT:-90}" ]] && log_warn "High memory usage: ${pct}%"
        fi
    else
        log_warn "'free' not available; skipping memory check."
    fi
}

# health_load : show CPU count and load averages.
health_load() {
    header "CPU & Load"
    local cores
    cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo "?")
    echo "CPU cores: $cores"
    # Load averages live in /proc/loadavg (1, 5, 15 minute averages).
    if [[ -r /proc/loadavg ]]; then
        read -r l1 l5 l15 _ < /proc/loadavg
        echo "Load average (1/5/15 min): $l1 $l5 $l15"
    else
        uptime
    fi
}

# health_uptime : show how long the system has been up.
health_uptime() {
    header "Uptime"
    uptime -p 2>/dev/null || uptime
}

# health_top : top processes by memory (a quick offenders list).
health_top() {
    header "Top 5 processes by memory"
    # ps with selected columns, sorted by %MEM descending, first 5.
    # The trailing '|| true' keeps a SIGPIPE from 'head' (under pipefail/set -e)
    # from aborting the script when ps produces many lines.
    if ps -eo pid,comm,%cpu,%mem --sort=-%mem >/dev/null 2>&1; then
        ps -eo pid,comm,%cpu,%mem --sort=-%mem 2>/dev/null | head -6 || true
    else
        ps aux | sort -rnk4 | head -6 || true
    fi
}

# health_report : run everything, with an overall banner.
health_report() {
    log_info "Running system health report"
    health_uptime
    health_load
    health_memory
    health_disk
    health_top
    echo
    log_info "Health report complete"
}
