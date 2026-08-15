#!/usr/bin/env bash
#
# lib/common.sh — shared helpers for the System Admin Toolkit.
# This file is meant to be SOURCED, not executed:  source lib/common.sh
# It provides: colors, logging, a die() helper, and small utilities.
# Concepts used: functions (L15), local scope (L16), redirection (L19),
#                error handling (L20), parameter expansion (L18).
# -----------------------------------------------------------------------------

# --- Colors (disabled automatically when output is not a terminal) -----------
if [[ -t 1 ]]; then                    # -t 1 = is stdout a terminal?
    readonly C_RESET=$'\033[0m'
    readonly C_RED=$'\033[31m'
    readonly C_GREEN=$'\033[32m'
    readonly C_YELLOW=$'\033[33m'
    readonly C_BLUE=$'\033[34m'
    readonly C_BOLD=$'\033[1m'
else                                    # piping/redirecting -> no color codes
    readonly C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_BOLD=""
fi

# --- Logging ------------------------------------------------------------------
# LOG_FILE may be set by the caller; default to a per-user log in /tmp.
LOG_FILE="${LOG_FILE:-/tmp/sysadmin-toolkit.log}"

# _log LEVEL COLOR MESSAGE... : timestamped line to stderr AND the log file.
_log() {
    local level="$1" color="$2"; shift 2
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    # Colored to the screen (stderr), plain to the log file.
    echo "${color}[${ts}] [${level}] $*${C_RESET}" >&2
    echo "[${ts}] [${level}] $*" >> "$LOG_FILE"
}

log_info()  { _log "INFO"  "$C_GREEN"  "$@"; }
log_warn()  { _log "WARN"  "$C_YELLOW" "$@"; }
log_error() { _log "ERROR" "$C_RED"    "$@"; }

# --- die: print an error and exit ---------------------------------------------
die() {
    log_error "$@"
    exit 1
}

# --- require_cmd: ensure an external command exists ---------------------------
require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

# --- print a section header ---------------------------------------------------
header() {
    echo
    echo "${C_BOLD}${C_BLUE}=== $* ===${C_RESET}"
}

# --- confirm: yes/no prompt, returns success on yes ---------------------------
confirm() {
    local prompt="${1:-Are you sure?}" answer
    read -r -p "$prompt [y/N] " answer
    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}
