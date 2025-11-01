#!/usr/bin/env bash
set -euo pipefail

# ---- resolve paths ----
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- source libs (optional) ----
# lib.sh 是可选的，若不存在不报错
if [ -f "$ROOT/lib.sh" ]; then
  # shellcheck source=/dev/null
  source "$ROOT/lib.sh"
else
  log(){ :; }          # 占位
  backup_file(){ :; }  # 占位
fi

# ---- source ui ----
# shellcheck source=/dev/null
source "$ROOT/ui.sh"

# ---- source features (若存在才启用菜单项) ----
declare -A FEATURE_MAP=()
if [ -f "$ROOT/features/core_os.sh" ];   then source "$ROOT/features/core_os.sh";   FEATURE_MAP["系统换源"]="run_os_mirror"; fi
if [ -f "$ROOT/features/core_bt.sh" ];   then source "$ROOT/features/core_bt.sh";   FEATURE_MAP["一键安装宝塔"]="run_bt_install"; fi
if [ -f "$ROOT/features/core_dkr.sh" ];  then source "$ROOT/features/core_dkr.sh";  FEATURE_MAP["Docker 换源"]="run_dkr_mirror"; fi
if [ -f "$ROOT/features/core_disk.sh" ]; then source "$ROOT/features/core_disk.sh"; FEATURE_MAP["数据盘挂载"]="run_disk_mount"; fi

# ---- defaults & args ----
LANG_CODE="zh"
THEME="dark"
NON_INTERACTIVE=0
ASSUME_YES=0

for arg in "$@"; do
  case "$arg" in
    --lang=*) LANG_CODE="${arg#*=}";;
    --theme=*) THEME="${arg#*=}";;
    --non-interactive) NON_INTERACTIVE=1;;
    -y|--yes) ASSUME_YES=1;;
    -h|--help)
      cat <<'EOF'
Usage: ./main.sh [--lang=zh|en] [--theme=dark|light] [--non-interactive] [-y|--yes]
Options:
  --lang=zh|en          UI 语言
  --theme=dark|light    终端主题
  --non-interactive     无需手动确认，按默认路径执行
  -y, --yes             遇到确认默认选择“是”
EOF
      exit 0
      ;;
  esac
done

# ---- apply theme & language (轻量) ----
ui_apply_theme "$THEME"
ui_set_lang "$LANG_CODE"

# ---- deps ----
# gum/fzf 不一定强制，ui.sh 内部会优雅降级；这里建议补齐体验更好
ui_require_deps gum fzf jq curl

# ---- build menu ----
build_menu_items() {
  local items=()
  local key
  for key in "系统换源" "一键安装宝塔" "Docker 换源" "数据盘挂载"; do
    if [[ -n "${FEATURE_MAP[$key]:-}" ]]; then
      items+=("$key")
    fi
  done
  items+=("退出")
  printf "%s\n" "${items[@]}"
}

run_choice() {
  local choice="$1"
  if [[ "$choice" == "退出" ]]; then
    ui_ok "已退出"
    exit 0
  fi
  local fn="${FEATURE_MAP[$choice]:-}"
  if [[ -z "$fn" ]]; then
    ui_warn "功能 [$choice] 暂不可用（未找到对应脚本）"
    return
  fi
  # 传递非交互/默认确认参数给功能函数（各 feature 自行决定是否使用）
  "$fn" "$NON_INTERACTIVE" "$ASSUME_YES"
}

main_menu() {
  ui_header "OneShell" "Linux 服务器初始化与优化工具"
  while true; do
    mapfile -t OPTIONS < <(build_menu_items)
    local pick
    pick="$(ui_select "请选择要执行的功能：" "${OPTIONS[@]}")"
    [ -z "$pick" ] && { ui_warn "未选择任何内容"; break; }
    ui_divider
    run_choice "$pick"
    ui_divider
    if (( NON_INTERACTIVE == 1 )); then
      # 非交互模式执行一次后退出
      break
    else
      ui_confirm "返回主菜单？" || break
    fi
  done
}

main_menu
