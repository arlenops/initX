#!/usr/bin/env bash
set -euo pipefail

# ------------- helpers -------------
_has() { command -v "$1" >/dev/null 2>&1; }

_detect_pm() {
  _has apt-get && { echo apt; return; }
  _has dnf && { echo dnf; return; }
  _has yum && { echo yum; return; }
  _has zypper && { echo zypper; return; }
  echo none
}

_try_install() {
  local pkgs=("$@")
  local pm; pm="$(_detect_pm)"
  case "$pm" in
    apt) sudo apt-get update -y >/dev/null 2>&1 || true; sudo apt-get install -y "${pkgs[@]}" || true;;
    dnf) sudo dnf install -y "${pkgs[@]}" || true;;
    yum) sudo yum install -y "${pkgs[@]}" || true;;
    zypper) sudo zypper install -y "${pkgs[@]}" || true;;
    none) return 1;;
  esac
}

# ------------- theme & lang -------------
C_PRIMARY="\033[38;5;81m"
C_OK="\033[32m"
C_WARN="\033[33m"
C_ERR="\033[31m"
C_DIM="\033[2m"
C_RESET="\033[0m"

ui_apply_theme() {
  local t="${1:-dark}"
  if [[ "$t" == "light" ]]; then
    C_PRIMARY="\033[38;5;26m"
  else
    C_PRIMARY="\033[38;5;81m"
  fi
}

_UI_LANG="zh"
ui_set_lang() { _UI_LANG="${1:-zh}"; }

# ------------- status lines -------------
ui_divider() { printf "${C_DIM}----------------------------------------${C_RESET}\n"; }
ui_ok()      { printf "${C_OK}✓ %s${C_RESET}\n" "$1"; }
ui_warn()    { printf "${C_WARN}! %s${C_RESET}\n" "$1"; }
ui_err()     { printf "${C_ERR}✗ %s${C_RESET}\n" "$1"; }
ui_note()    { printf "• %s\n" "$1"; }

# ------------- header -------------
ui_header() {
  local title="$1" subtitle="${2:-}"
  if _has gum; then
    if [[ -n "$subtitle" ]]; then
      gum style --border double --margin "1 2" --padding "1 2" --bold --align center "$title" -- "$subtitle"
    else
      gum style --border double --margin "1 2" --padding "1 2" --bold --align center "$title"
    fi
  else
    printf "${C_PRIMARY}== %s ==${C_RESET}\n" "$title"
    [[ -n "$subtitle" ]] && printf "%s\n" "$subtitle"
  fi
}

# ------------- selection -------------
ui_select() {
  local prompt="$1"; shift
  local items=("$@")
  if _has gum; then
    printf "%s\n" "${items[@]}" | gum choose --height 12 --cursor-prefix "› "
  elif _has fzf; then
    printf "%s\n" "${items[@]}" | fzf --prompt="$prompt> " --height=15 --reverse
  else
    ui_note "$prompt"
    local i=1
    for it in "${items[@]}"; do printf "  %d) %s\n" "$i" "$it"; i=$((i+1)); done
    read -r -p "> " idx
    [[ "$idx" =~ ^[0-9]+$ ]] && echo "${items[$((idx-1))]}" || echo ""
  fi
}

# ------------- confirm -------------
ui_confirm() {
  local msg="$1"
  if _has gum; then
    gum confirm "$msg"
  else
    read -r -p "$msg [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
  fi
}

# ------------- spinner wrapper -------------
ui_spin() {
  # ui_spin "描述" cmd args...
  local msg="$1"; shift
  if _has gum; then
    gum spin --spinner dot --title "$msg" -- "$@"
  else
    ui_note "$msg..."
    "$@"
  fi
}

# ------------- dependency management -------------
ui_require_deps() {
  # 用法：ui_require_deps gum fzf jq curl
  local need_install=()
  local cmd
  for cmd in "$@"; do
    _has "$cmd" || need_install+=("$cmd")
  done

  if ((${#need_install[@]}==0)); then
    return 0
  fi

  ui_warn "缺少依赖：${need_install[*]}"
  ui_note "尝试自动安装（需要 sudo），或按提示自行安装。"

  if _try_install "${need_install[@]}"; then
    ui_ok "依赖安装完成"
    return 0
  fi

  ui_warn "自动安装失败或不可用，请手动安装：${need_install[*]}"
  # 不中断执行；gum/fzf 缺失时会自动降级到纯文本
  return 0
}
