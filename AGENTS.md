# Repository Guidelines

## Project Structure & Module Organization
Each top-level directory hosts an independent console. `bt/` handles Baota panel management, `docker/` manages container runtime tweaks, and `linux/` focuses on system package mirrors. Within every console, `main.sh` presents the menu while `tasks/` stores focused subroutines (`install.sh`, `migrate.sh`, etc.). Shared UI helpers, color constants, and loader utilities reside in `lib.sh`; source it from console entry points via `source "${ROOT_DIR}/lib.sh"`. When extending functionality, add a new script under the relevant `tasks/` directory, expose functions there, and register them in that console’s `menu_options`.

## Build, Test, and Development Commands
- `bash -n path/to/script.sh` — run against each console (`bash -n bt/main.sh`) and newly added task file.
- `shellcheck path/to/script.sh` — static analysis; accompany any suppression with a brief comment.
- `./bt/main.sh`, `./docker/main.sh`, `./linux/main.sh` — launch a specific console; prepend `DEBUG=1` for verbose logging.
- `rg "todo" -g'*.sh'` — quick scan for remaining TODO placeholders before submitting changes.

## Coding Style & Naming Conventions
Target Bash 5, remain POSIX-friendly. Follow two-space indentation, `snake_case` for functions, uppercase for exported environment variables. Place `set -euo pipefail` at the top of executables, quote parameter expansions by default, and prefer `$(command)` substitution. Keep UI copy in simplified Chinese and render menus through `print_box_line`/`print_menu_option` to preserve alignment. Avoid hard-coded absolute paths; derive locations relative to `SCRIPT_DIR` or `ROOT_DIR`.

## Testing Guidelines
Use Bats (or lightweight Bash checks) per console. Store suites alongside code, e.g. `bt/tests/install.bats`, mirroring the function names they exercise. Test cases should describe the behaviour (`"迁移失败时仍保留原目录"`), stub external commands where needed, and confirm that exit codes and prompts match expectations. Combine these runs with `shellcheck` to catch style regressions; include command excerpts in PRs when tests cover interactive flows.

## Commit & Pull Request Guidelines
Compose imperative commit subjects ≤72 characters, with optional prefixes like `feat:` or `fix:`. Summaries must cover motivation, risk areas, and rollback steps, referencing work items via `Refs #123` or `Fixes #123`. Pull requests should highlight structural changes (directory moves, new tasks), list manual/automated validation, attach relevant terminal output, and flag any TODOs. Before requesting review ensure each console launches cleanly, menus map to existing task functions, and lint/test commands succeed.
