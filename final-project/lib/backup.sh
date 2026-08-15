#!/usr/bin/env bash
#
# lib/backup.sh — timestamped backups with retention for the toolkit.
# SOURCED by sysadmin-toolkit.sh. Uses helpers from lib/common.sh.
# Concepts: arguments (L21), files & dirs (L22), parameter expansion (L18),
#           loops (L11/12), error handling (L20), arrays (L14).
# -----------------------------------------------------------------------------

# backup_create SOURCE_DIR [DEST_DIR]
#   Creates a gzip'd tarball of SOURCE_DIR in DEST_DIR (default: $BACKUP_DIR
#   or /tmp/backups), named like  <basename>-YYYYmmdd-HHMMSS.tar.gz
backup_create() {
    local src="${1:?backup_create: source directory required}"
    local dest="${2:-${BACKUP_DIR:-/tmp/backups}}"

    require_cmd tar
    [[ -d "$src" ]] || die "source is not a directory: $src"
    mkdir -p "$dest" || die "cannot create destination: $dest"

    local base stamp archive
    base="$(basename "$src")"
    stamp="$(date +%Y%m%d-%H%M%S)"
    archive="${dest}/${base}-${stamp}.tar.gz"

    log_info "Backing up '$src' -> '$archive'"
    # -c create, -z gzip, -f file. -C changes dir so paths in the archive are
    # relative (cleaner restores). 2>/dev/null hides permission noise.
    if tar -czf "$archive" -C "$(dirname "$src")" "$base" 2>/dev/null; then
        local size
        size="$(du -h "$archive" | cut -f1)"
        log_info "Backup complete: $archive ($size)"
        echo "$archive"            # print the path so callers can capture it
    else
        die "backup failed for: $src"
    fi
}

# backup_rotate DEST_DIR PREFIX KEEP
#   Keeps only the newest KEEP backups matching PREFIX-*.tar.gz; deletes older.
backup_rotate() {
    local dest="${1:?dest required}"
    local prefix="${2:?prefix required}"
    local keep="${3:-${BACKUP_KEEP:-5}}"

    [[ -d "$dest" ]] || { log_warn "no backup dir to rotate: $dest"; return 0; }

    # Collect matching files, newest first, into an array (L14).
    local files=()
    while IFS= read -r f; do
        files+=("$f")
    done < <(ls -1t "${dest}/${prefix}-"*.tar.gz 2>/dev/null)

    local total="${#files[@]}"
    if (( total <= keep )); then
        log_info "Rotation: $total backup(s) present, keep=$keep — nothing to delete."
        return 0
    fi

    log_info "Rotation: keeping newest $keep of $total backups."
    local i
    for (( i = keep; i < total; i++ )); do
        log_warn "Removing old backup: ${files[$i]}"
        rm -f "${files[$i]}"
    done
}

# backup_list DEST_DIR : show existing backups with sizes.
backup_list() {
    local dest="${1:-${BACKUP_DIR:-/tmp/backups}}"
    header "Backups in $dest"
    if [[ -d "$dest" ]] && ls -1 "$dest"/*.tar.gz >/dev/null 2>&1; then
        ls -lh "$dest"/*.tar.gz | awk '{ print $9, "("$5")" }'
    else
        echo "(no backups found)"
    fi
}

# backup_run SOURCE_DIR : full workflow — create then rotate.
backup_run() {
    local src="${1:?backup_run: source directory required}"
    local dest="${BACKUP_DIR:-/tmp/backups}"
    backup_create "$src" "$dest" >/dev/null
    backup_rotate "$dest" "$(basename "$src")" "${BACKUP_KEEP:-5}"
    backup_list "$dest"
}
