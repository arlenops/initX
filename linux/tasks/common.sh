#!/usr/bin/env bash
#
# Linux 软件源控制台共享工具。

linux_show_todo() {
  local title=$1
  shift

  printf '%s[待实现]%s %s\n' "${COLOR_WARNING}" "${COLOR_RESET}" "${title}"
  local line
  for line in "$@"; do
    printf '  - %s\n' "${line}"
  done
}
