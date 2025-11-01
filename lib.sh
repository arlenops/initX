#!/usr/bin/env bash
set -euo pipefail

# ===== 文件操作 =====
# 备份文件（如果存在）
backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    local bak="${file}.bak.$(date +%s)"
    sudo cp -a "$file" "$bak"
    echo "🗂 已备份文件：$file → $bak"
  fi
}

# 恢复最近的备份（可选）
restore_latest_backup() {
  local file="$1"
  local bak
  bak="$(ls -t "${file}".bak.* 2>/dev/null | head -n 1 || true)"
  if [ -n "$bak" ]; then
    sudo cp -a "$bak" "$file"
    echo "✅ 已从备份恢复：$file"
  else
    echo "⚠️ 未找到 $file 的备份"
  fi
}

# ===== 权限 & 环境 =====
# 检查 root 权限
need_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 此操作需要 root 权限"
    exit 1
  fi
}

# 检查命令是否存在
has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# 判断发行版
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  else
    uname -s | tr '[:upper:]' '[:lower:]'
  fi
}

# 简单检测网络连通性
is_online() {
  ping -c1 -W1 8.8.8.8 >/dev/null 2>&1
}

# ===== 命令安全执行包装 =====
# 带提示的安全执行（失败会退出）
safe_exec() {
  local desc="$1"; shift
  echo "▶️ $desc..."
  if "$@"; then
    echo "✅ 完成：$desc"
  else
    echo "❌ 失败：$desc"
    exit 1
  fi
}

# ===== 小工具函数 =====
timestamp() {
  date '+%Y%m%d-%H%M%S'
}

trim() {
  # 去除字符串前后空格
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  echo -n "$var"
}

rand_str() {
  local len="${1:-8}"
  tr -dc A-Za-z0-9 </dev/urandom | head -c "$len"
}
