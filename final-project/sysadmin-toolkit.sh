#!/usr/bin/env bash
#
# sysadmin-toolkit.sh — the CAPSTONE project for the Bash Zero-to-Hero course.
# A menu-driven (and scriptable) system administration toolkit that ties
# together everything from the course:
#   shebang & structure (L1/2)   variables (L3)        input (L4)
#   quoting (L5)                  arithmetic (L6)       substitution (L7)
#   conditionals/case (L8/10)    loops & select (11-13) arrays (L14)
#   functions & scope (L15/16)   strings & params (17/18)
#   redirection & here-docs (19) error handling/trap (20)
#   arguments & getopts (21)     files & find (22)      text tools (23)
#   processes (24)               best practices (25)
#
# USAGE:
#   ./sysadmin-toolkit.sh                 # interactive menu
#   ./sysadmin-toolkit.sh health          # run health report
#   ./sysadmin-toolkit.sh backup DIR      # back up DIR (with rotation)
#   ./sysadmin-toolkit.sh analyze FILE    # summarize a log file
#   ./sysadmin-toolkit.sh -h              # help
#
# OPTIONS:
#   -d N   disk warning threshold percent (default 80)
#   -k N   number of backups to keep when rotating (default 5)
#   -l F   log file to write toolkit activity to
#   -h     show help
# -----------------------------------------------------------------------------

# ---- Best-practice strict mode (Lesson 25/20) -------------------------------
set -euo pipefail

# ---- Resolve this script's directory so we can source lib/ reliably ---------
# ${BASH_SOURCE[0]} is this file; cd to its dir and pwd to get an absolute path.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
readonly SCRIPT_DIR
readonly SCRIPT_NAME="${0##*/}"
readonly VERSION="1.0.0"

# ---- Load the library modules (Lesson 19: source) ---------------------------
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/health.sh
source "${SCRIPT_DIR}/lib/health.sh"
# shellcheck source=lib/backup.sh
source "${SCRIPT_DIR}/lib/backup.sh"
# shellcheck source=lib/loganalyzer.sh
source "${SCRIPT_DIR}/lib/loganalyzer.sh"

# ---- Configurable defaults (overridable by options/env; Lesson 18) ----------
export DISK_WARN_PCT="${DISK_WARN_PCT:-80}"
export BACKUP_KEEP="${BACKUP_KEEP:-5}"
export BACKUP_DIR="${BACKUP_DIR:-/tmp/backups}"

usage() {
    cat << EOF
${C_BOLD}System Admin Toolkit v${VERSION}${C_RESET}

Usage:
  ${SCRIPT_NAME} [options] [command] [args]

Commands:
  health              Run a full system health report
  backup <dir>        Create a timestamped backup of <dir> and rotate old ones
  analyze <file>      Summarize a log file (levels, top errors, timeline)
  search <file> <pat> Search a log file for a pattern
  menu                Launch the interactive menu (default if no command)

Options:
  -d N   disk warning threshold %% (default ${DISK_WARN_PCT})
  -k N   backups to keep on rotate (default ${BACKUP_KEEP})
  -l F   activity log file (default ${LOG_FILE})
  -h     show this help

Examples:
  ${SCRIPT_NAME} health
  ${SCRIPT_NAME} -k 3 backup /etc
  ${SCRIPT_NAME} analyze /var/log/syslog
EOF
}

# ---- Interactive menu (Lesson 13: select) -----------------------------------
interactive_menu() {
    local choice
    PS3=$'\n'"Choose an option (number): "
    local options=(
        "System health report"
        "Create a backup"
        "List backups"
        "Analyze a log file"
        "Search a log file"
        "Show activity log"
        "Quit"
    )
    header "System Admin Toolkit — Main Menu"
    select choice in "${options[@]}"; do
        case "$REPLY" in
            1) health_report ;;
            2)
                read -r -p "Directory to back up: " dir
                [[ -n "$dir" ]] && backup_run "$dir" || log_warn "No directory given."
                ;;
            3) backup_list ;;
            4)
                read -r -p "Path to log file: " f
                [[ -n "$f" ]] && log_summary "$f" || log_warn "No file given."
                ;;
            5)
                read -r -p "Log file: " f
                read -r -p "Pattern: " p
                [[ -n "$f" && -n "$p" ]] && log_search "$f" "$p" || log_warn "Need file and pattern."
                ;;
            6)
                header "Activity log ($LOG_FILE)"
                [[ -f "$LOG_FILE" ]] && tail -n 20 "$LOG_FILE" || echo "(empty)"
                ;;
            7) log_info "Goodbye!"; break ;;
            *) log_warn "Invalid choice: $REPLY" ;;
        esac
    done
}

# ---- main: parse options, then dispatch the command (Lesson 21) -------------
main() {
    local opt
    OPTIND=1
    while getopts ":d:k:l:h" opt; do
        case "$opt" in
            d) DISK_WARN_PCT="$OPTARG" ;;
            k) BACKUP_KEEP="$OPTARG" ;;
            l) LOG_FILE="$OPTARG" ;;
            h) usage; exit 0 ;;
            :)  die "option -$OPTARG requires a value (see -h)" ;;
            \?) die "unknown option -$OPTARG (see -h)" ;;
        esac
    done
    shift $(( OPTIND - 1 ))

    # Make sure the log file is writable; fall back if not.
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/${SCRIPT_NAME}.log"
    log_info "${SCRIPT_NAME} v${VERSION} started (command: ${1:-menu})"

    local command="${1:-menu}"
    [[ "$#" -gt 0 ]] && shift || true

    case "$command" in
        health)  health_report ;;
        backup)  backup_run "${1:?Usage: $SCRIPT_NAME backup <dir>}" ;;
        analyze) log_summary "${1:?Usage: $SCRIPT_NAME analyze <file>}" ;;
        search)  log_search "${1:?need file}" "${2:?need pattern}" ;;
        menu)    interactive_menu ;;
        *)       die "unknown command: $command (see -h)" ;;
    esac
}

main "$@"
