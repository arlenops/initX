#!/usr/bin/env bash
#
# 宝塔面板任务共享工具。

bt_show_todo() {
  local title=$1
  shift

  printf '%s[待实现]%s %s\n' "${COLOR_WARNING}" "${COLOR_RESET}" "${title}"
  local line
  for line in "$@"; do
    printf '  - %s\n' "${line}"
  done
}
