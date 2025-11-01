# Repository Guidelines

## Project Structure & Module Organization

The repository is organized around Bash modules. `main.sh` acts as the entry orchestrator, responsible for routing arguments, loading configuration, and dispatching feature modules. `ui.sh` defines all terminal UI helpers powered by `gum` and `fzf`, ensuring consistent style across commands. Shared utilities such as logging, backup, and dependency checks belong in `lib.sh`. The `features/` directory stores feature-specific logic like `core_os.sh` for mirror switching, `core_bt.sh` for BtPanel installation, `core_dkr.sh` for Docker mirror management, and `core_disk.sh` for data disk mounting.
When introducing a new capability, add a `core_<topic>.sh` module under `features/` and source it from `main.sh`. Each feature must include its own dependency check (`gum`, `fzf`, `jq`, `curl`) and reuse UI components from `ui.sh` for a uniform interaction experience. Any configuration templates or test data should reside beside the corresponding feature to keep the project modular and maintainable.

## Build, Test, and Development Commands

* `bash -n path/to/file.sh` — quick syntax validation for any script before committing.
* `shellcheck path/to/file.sh` — run linting; only silence warnings with documented justification.
* `./main.sh` — executes the orchestrator for full interactive testing.
* `./main.sh --non-interactive -y` — verifies non-interactive automation paths.
* `DEBUG=1 ./main.sh` — enables verbose logging for debugging purposes.
* `gum style --border double "UI preview"` — test UI appearance independently.
  All scripts should run cleanly in Bash 5 environments with `set -euo pipefail` enabled. Validate the behavior of each module both inside and outside the main orchestrator to ensure standalone usability.

## Coding Style & Naming Conventions

Target Bash 5 while remaining POSIX-friendly. Use two-space indentation, define functions as `run_feature() { ... }`, and prefer lowercase `snake_case` for variables. Reserve uppercase names for exported environment variables. Always include `set -euo pipefail` near the top of each executable, quote parameter expansions defensively, and rely on `$(...)` for command substitution instead of backticks. Detect dependencies with `command -v` instead of `which`.
Source shared utilities using:

```
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
```

Use `ui_ok`, `ui_warn`, and `ui_err` for consistent status output, and structure all user interactions through `gum` or `fzf` components for clarity and aesthetics. Each feature script should remain self-contained and runnable on its own while adhering to the shared UI and logging patterns.

## Testing Guidelines

Behavioral tests live alongside the features they validate. Create `features/tests/` and place Bats test files named after the script under test, for example `core_disk.bats`. Describe each test scenario in natural language (`"disk: mounts data partition successfully"`), and stub external dependencies with `bats-mock` where applicable.
Run `bats features/tests` locally to ensure coverage, and complement it with `shellcheck` to detect stylistic regressions. Mock system-level commands in CI to avoid destructive operations. Test each feature independently before integration into `main.sh`.

## Commit & Pull Request Guidelines

Use imperative, 72-character subjects and include a type prefix when meaningful (`feat: add docker mirror switching`). Provide a concise body explaining the motivation, user impact, and rollback plan. Reference issues using `Refs #123` or `Fixes #123`.
Pull requests must summarize functional changes, list validation steps, and attach relevant terminal output or screenshots demonstrating UI behavior. Ensure that `shellcheck` and Bats tests pass locally before requesting review. Each pull request should focus on one logical change to keep review cycles efficient and predictable.
