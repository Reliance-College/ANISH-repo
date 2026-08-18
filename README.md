# Final Project — System Admin Toolkit

This capstone ties together **every concept** from the course into one real, useful program: a
menu-driven (and scriptable) system administration toolkit.

By building (or studying, extending, and grading) this project, you prove you can write
**project-grade** Bash.

---

## What it does

A single command-line tool with three core features plus an interactive menu:

1. **System health report** — uptime, CPU/load, memory, disk usage (with threshold warnings),
   and the top memory-hungry processes.
2. **Backup utility** — creates timestamped `.tar.gz` backups of a directory and automatically
   **rotates** (deletes) old ones beyond a keep-count.
3. **Log analyzer** — summarizes a log file: line totals, counts by level, the top error
   messages, search, and an events-per-hour timeline.

Everything is **logged** with timestamps, output is **colorized** (only when printing to a
terminal), and the tool works both **interactively** and as a **scriptable CLI**.

---

## File layout

```
final-project/
├── README.md              ← you are here
├── sysadmin-toolkit.sh    ← main entry point (option parsing + dispatch + menu)
└── lib/                   ← sourced modules, one concern each
    ├── common.sh          ← colors, logging, die(), confirm(), require_cmd()
    ├── health.sh          ← system health checks
    ├── backup.sh          ← backup create / rotate / list
    └── loganalyzer.sh     ← log summary / search / timeline
```

This **`main` + sourced library modules** structure (Lesson 25) is exactly how real-world
Bash tools are organized.

---

## How to run

```bash
cd final-project
chmod +x sysadmin-toolkit.sh

# Interactive menu (default):
./sysadmin-toolkit.sh

# Or run a single command directly:
./sysadmin-toolkit.sh health
./sysadmin-toolkit.sh backup /etc
./sysadmin-toolkit.sh analyze /var/log/syslog
./sysadmin-toolkit.sh search /var/log/syslog "error"

# Options:
./sysadmin-toolkit.sh -d 70 health        # warn when a disk is >= 70% full
./sysadmin-toolkit.sh -k 3 backup ~/notes # keep only the newest 3 backups
./sysadmin-toolkit.sh -h                  # help
```

Environment overrides (Lesson 18): `BACKUP_DIR`, `BACKUP_KEEP`, `DISK_WARN_PCT`, `LOG_FILE`.

---

## Concept → code map

| Course concept | Where it's used |
|----------------|-----------------|
| Shebang, structure, comments (L1–2) | every file header; `main "$@"` at the bottom |
| Variables / readonly (L3) | `VERSION`, `SCRIPT_DIR`, config vars |
| Quoting (L5) | every `"$var"`, `"${arr[@]}"` |
| Arithmetic (L6) | memory %, disk %, rotation index loop |
| Command substitution (L7) | `$(date ...)`, `$(basename ...)`, `$(du -h ...)` |
| Conditionals & case (L8/10) | option parsing, command dispatch, menu actions |
| Loops & select (L11–13) | rotation loop, threshold loop, the interactive menu |
| Arrays (L14) | menu options, list of backup files |
| Functions & scope (L15/16) | every feature is a `local`-scoped function |
| Strings & parameter expansion (L17/18) | `${0##*/}`, `${1:?...}`, `${VAR:-default}` |
| Redirection & here-docs (L19) | `>&2` logging, `cat << EOF` help/usage, `< <(...)` |
| Error handling & trap (L20) | `set -euo pipefail`, `die()`, SIGPIPE guards |
| Arguments & getopts (L21) | `main()` option/command parsing |
| Files & find (L22) | backups, `mkdir -p`, `tar`, file tests |
| Text processing (L23) | `df`/`awk`, `grep`/`sed`/`sort`/`uniq` in the analyzer |
| Processes (L24) | `ps` in the health report |
| Best practices (L25) | strict mode, modular `lib/`, validation, logging |

---

## Build-it-yourself guide

If you're a student building this from scratch, do it in stages — test after each:

1. **Skeleton:** create `sysadmin-toolkit.sh` with the shebang, `set -euo pipefail`, a
   `usage()` here-doc, and a `main "$@"` that just prints help. (L1, L19, L25)
2. **Library + logging:** make `lib/common.sh` with `log_info/warn/error` and `die`. Source it
   from main. Resolve `SCRIPT_DIR` so sourcing works from anywhere. (L15, L19, L20)
3. **Option parsing:** add `getopts` for `-d/-k/-l/-h` and a `case` to dispatch the first
   non-option argument to a command. (L10, L21)
4. **Health report:** build `lib/health.sh` one function at a time (`uptime`, `load`, `memory`,
   `disk`, `top`). Use `df`/`free`/`awk`. (L7, L23)
5. **Backups:** build `lib/backup.sh` — `backup_create` (tar + timestamp), then `backup_rotate`
   (array of files, keep newest N), then `backup_list`. (L14, L18, L22)
6. **Log analyzer:** build `lib/loganalyzer.sh` — `log_summary`, `log_search`, `log_timeline`
   using the text toolkit. (L23)
7. **Interactive menu:** add `interactive_menu` with `select`, wiring each option to a feature.
   (L13)
8. **Polish:** colors, input validation, the activity log, and run `shellcheck` + `bash -n`.
   (L25)

---

## Grading rubric (100 pts)

| Criteria | Points |
|----------|-------:|
| Runs without errors; `bash -n` clean; passes `shellcheck` | 15 |
| `set -euo pipefail` + strict-mode structure (`main "$@"`) | 10 |
| Proper option/command parsing with `getopts` + `case` | 10 |
| Functions are small, `local`-scoped, single-purpose | 10 |
| Health report works and warns on thresholds | 15 |
| Backup creates timestamped archive **and** rotates correctly | 15 |
| Log analyzer summarizes levels + top errors | 15 |
| Logging, colors, input validation, and a `die()` helper | 10 |
| **Total** | **100** |

Stretch goals (bonus): add a `--json` output mode, email/Slack alerts on warnings, a
`restore` command for backups, or unit tests with [bats](https://github.com/bats-core/bats-core).

---

## Try it safely right now

```bash
# Make a throwaway directory and log to play with:
mkdir -p /tmp/demo/sub && echo "hello" > /tmp/demo/file.txt
printf '%s\n' \
  "2026-06-14 10:01 INFO started" \
  "2026-06-14 10:02 ERROR db timeout" \
  "2026-06-14 11:03 ERROR db timeout" \
  "2026-06-14 11:05 WARN slow query" > /tmp/demo/app.log

./sysadmin-toolkit.sh health
./sysadmin-toolkit.sh -k 2 backup /tmp/demo
./sysadmin-toolkit.sh analyze /tmp/demo/app.log
```
