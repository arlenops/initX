#!/usr/bin/env bash
#
# Linux 软件源管理控制台。

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=../lib.sh
source "${ROOT_DIR}/lib.sh"

load_feature_modules "${SCRIPT_DIR}/tasks"

animate_welcome() {
  printf '\033[?25l'
  trap cleanup_cursor EXIT

  clear_screen
  printf '%s+----------------------------------------+%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
  print_box_line "Linux 源管理助手"
  print_box_line "快速切换与恢复官方源"
  printf '%s+----------------------------------------+%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"

  printf '\n'
  slow_print "${COLOR_SECONDARY}正在载入 Linux 控制台 " 0.01
  local frames=('-' '\\' '|' '/')
  local frame
  for ((i = 0; i < 16; i++)); do
    frame=${frames[i % ${#frames[@]}]}
    printf '\r%s检查系统 %s' "${COLOR_SECONDARY}" "${frame}"
    sleep 0.08
  done
  printf '\r%s准备完毕！           %s\n\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  cleanup_cursor
}

menu_options=(
  "Linux 安装源切换"
  "恢复使用官方源"
  "返回上一级"
)

render_menu() {
  printf '%s+----------------------------------------+%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
  print_box_line "Linux 源控制台"
  printf '%s+----------------------------------------+%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
  local idx
  for idx in "${!menu_options[@]}"; do
    print_menu_option "$((idx + 1))" "${menu_options[idx]}"
    sleep 0.02
  done
  printf '%s+----------------------------------------+%s\n' "${COLOR_PRIMARY}" "${COLOR_RESET}"
}

run_feature() {
  local handler=$1

  if [[ "$(type -t "${handler}" 2>/dev/null)" == "function" ]]; then
    printf '\n%s>> 执行 %s%s%s\n\n' "${COLOR_SECONDARY}" "${COLOR_HILIGHT}" "${handler}" "${COLOR_RESET}"
    "${handler}"
  else
    printf '\n%s!! 功能 %s 暂未实现。%s\n\n' "${COLOR_WARNING}" "${handler}" "${COLOR_RESET}"
  fi

  prompt_to_continue $'\033[38;5;111m按下回车返回 Linux 菜单...\033[0m'
}

dispatch_menu_option() {
  local choice=$1
  case "${choice}" in
    1)
      run_feature "linux_switch_mirror"
      ;;
    2)
      run_feature "linux_restore_official_sources"
      ;;
    3)
      printf '%s即将返回。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
      exit 0
      ;;
    *)
      printf '%s选项无效，请重试。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
      sleep 0.8
      ;;
  esac
}

main_menu() {
  animate_welcome

  while true; do
    clear_screen
    render_menu
    printf '%s请选择操作 [1-%d]: %s' "${COLOR_SECONDARY}" "${#menu_options[@]}" "${COLOR_RESET}"
    local selection
    IFS= read -r selection
    [[ -z "${selection}" ]] && continue
    dispatch_menu_option "${selection}"
  done
}

main_menu
