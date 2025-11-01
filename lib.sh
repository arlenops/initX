#!/usr/bin/env bash
#
# initx 共享函数库，提供 UI 样式、模块加载等通用能力。

if [[ -n "${INITX_LIB_SOURCED:-}" ]]; then
  return
fi
INITX_LIB_SOURCED=1

readonly COLOR_RESET=$'\033[0m'
readonly COLOR_PRIMARY=$'\033[38;5;80m'
readonly COLOR_SECONDARY=$'\033[38;5;111m'
readonly COLOR_HILIGHT=$'\033[38;5;156m'
readonly COLOR_WARNING=$'\033[38;5;203m'

pad_display_width() {
  local text=$1
  local width=$2

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$text" "$width" <<'PY'
import sys
import unicodedata

text = sys.argv[1]
width = int(sys.argv[2])

def display_width(s):
    total = 0
    for ch in s:
        if unicodedata.east_asian_width(ch) in ('F', 'W', 'A'):
            total += 2
        else:
            total += 1
    return total

current = display_width(text)
padding = max(width - current, 0)
sys.stdout.write(text + ' ' * padding)
PY
  else
    local current=${#text}
    local padding=$((width - current))
    ((padding < 0)) && padding=0
    printf '%s%*s' "${text}" "${padding}" ''
  fi
}

print_box_line() {
  local text=$1
  local padded
  padded=$(pad_display_width "${text}" 38)

  printf '%s|%s ' "${COLOR_PRIMARY}" "${COLOR_RESET}"
  printf '%s%s%s' "${COLOR_HILIGHT}" "${padded}" "${COLOR_RESET}"
  printf ' %s|%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
}

print_menu_option() {
  local index=$1
  local text=$2
  local label
  printf -v label '%2d > %s' "${index}" "${text}"
  local padded
  padded=$(pad_display_width "${label}" 38)

  printf '%s|%s ' "${COLOR_PRIMARY}" "${COLOR_RESET}"
  printf '%s%s%s' "${COLOR_SECONDARY}" "${padded}" "${COLOR_RESET}"
  printf ' %s|%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
}

cleanup_cursor() {
  printf '\033[?25h' || true
}

clear_screen() {
  printf '\033c'
}

slow_print() {
  local text=$1
  local delay=${2:-0.013}
  local char
  for ((i = 0; i < ${#text}; i++)); do
    char=${text:i:1}
    printf '%s' "${char}"
    sleep "${delay}"
  done
  printf '\n'
}

prompt_to_continue() {
  local message=${1:-$'\033[38;5;111m按下回车返回菜单...\033[0m'}
  read -rp "${message}" _
  printf '\n'
}

load_feature_modules() {
  local base_dir=$1
  shift || true
  local patterns=("$@")

  if [[ ${#patterns[@]} -eq 0 ]]; then
    patterns=("${base_dir}"/*.sh)
  else
    local expanded=()
    local pattern
    for pattern in "${patterns[@]}"; do
      expanded+=("${base_dir}/${pattern}")
    done
    patterns=("${expanded[@]}")
  fi

  shopt -s nullglob
  local module
  for module in "${patterns[@]}"; do
    [[ -f "${module}" ]] || continue
    # shellcheck source=/dev/null
    source "${module}"
  done
  shopt -u nullglob
}
