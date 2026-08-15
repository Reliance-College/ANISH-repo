#!/usr/bin/env bash
#
# lib/loganalyzer.sh — analyze a text log file for the toolkit.
# SOURCED by sysadmin-toolkit.sh. Uses helpers from lib/common.sh.
# Concepts: text processing (L23: grep/awk/sort/uniq), conditionals (L8),
#           associative arrays (L14), here-docs (L19).
# -----------------------------------------------------------------------------

# log_summary FILE
#   Prints totals, a breakdown by level (INFO/WARN/ERROR/...), and the most
#   frequent ERROR messages.
log_summary() {
    local file="${1:?log_summary: log file required}"
    [[ -f "$file" ]] || die "not a file: $file"
    [[ -r "$file" ]] || die "cannot read: $file"

    header "Log summary for $file"

    local lines
    lines=$(wc -l < "$file")
    echo "Total lines: $lines"

    echo
    echo "By level:"
    # Count occurrences of common level keywords anywhere in each line.
    local level
    for level in ERROR WARN WARNING INFO DEBUG; do
        local n
        # grep -c already prints 0 when there are no matches (and exits 1), so
        # we use '|| true' (NOT '|| echo 0', which would print a second 0 and
        # break the numeric test below) to satisfy 'set -e'.
        n=$(grep -c -w "$level" "$file" 2>/dev/null || true)
        [[ "${n:-0}" -gt 0 ]] && printf "  %-8s %d\n" "$level" "$n"
    done

    echo
    echo "Top 5 ERROR messages:"
    # Pull ERROR lines, strip everything up to and including 'ERROR', then
    # count & rank the remaining message text (classic count-and-rank idiom).
    if grep -qw ERROR "$file"; then
        # '|| true' guards against a SIGPIPE from 'head' aborting the script
        # (set -euo pipefail) when there are many ERROR lines.
        grep -w ERROR "$file" \
            | sed -E 's/^.*ERROR[: ]*//' \
            | sort | uniq -c | sort -rn | head -5 \
            | sed 's/^/  /' || true
    else
        echo "  (no ERROR lines found)"
    fi
}

# log_search FILE PATTERN
#   Show matching lines with line numbers and a total count.
log_search() {
    local file="${1:?file required}" pattern="${2:?pattern required}"
    [[ -f "$file" ]] || die "not a file: $file"
    header "Matches for '$pattern' in $file"
    local count
    count=$(grep -c -- "$pattern" "$file" 2>/dev/null || true); count="${count:-0}"
    # '|| true': 'head' closing early can SIGPIPE 'grep' (pipefail/set -e).
    grep -n --color=never -- "$pattern" "$file" | head -20 || true
    echo
    echo "Total matches: $count"
}

# log_timeline FILE
#   If lines start with a date/time, count events per hour (HH).
log_timeline() {
    local file="${1:?file required}"
    [[ -f "$file" ]] || die "not a file: $file"
    header "Events per hour in $file"
    # Match a time like 12:34 and grab the hour. Works for many log formats.
    grep -oE '[0-2][0-9]:[0-5][0-9]' "$file" \
        | cut -d: -f1 \
        | sort | uniq -c \
        | awk '{ printf "  %s:00  %s\n", $2, $1 }'
}
