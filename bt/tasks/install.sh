#!/usr/bin/env bash
#
# 宝塔面板：全新安装流程。

bt_install_fresh() {
  if ! bt_require_root; then
    return
  fi

  bt_print_system_overview
  bt_show_disk_overview

  local disk_entry selected_disk selected_size selected_has_partitions
  if disk_entry=$(bt_select_data_disk); then
    IFS='|' read -r selected_disk selected_size selected_has_partitions <<<"${disk_entry}"
    if bt_prepare_data_disk "${selected_disk}" "${selected_size}" "${selected_has_partitions}"; then
      printf '%s>> 数据盘已挂载到 /www，后续将直接安装宝塔面板。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
    else
      printf '%s!! 数据盘挂载中断，仍将继续执行宝塔安装。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    fi
  fi

  bt_run_official_install_script
}

bt_require_root() {
  if [[ "${EUID:-0}" -ne 0 ]]; then
    printf '%s请以 root 身份运行本操作后重试。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return 1
  fi
  return 0
}

bt_print_system_overview() {
  local pretty_name="未知发行版"
  local os_id="unknown"
  local version_id="unknown"

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    pretty_name=${PRETTY_NAME:-${NAME:-${pretty_name}}}
    os_id=${ID:-${os_id}}
    version_id=${VERSION_ID:-${version_id}}
  else
    pretty_name=$(uname -srv)
    os_id=$(uname -s | tr 'A-Z' 'a-z')
    version_id=$(uname -r)
  fi

  local package_manager="未识别"
  package_manager=$(bt_detect_package_manager)

  printf '%s系统信息：%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  printf '  - 发行版：%s\n' "${pretty_name}"
  printf '  - 标识符：%s %s\n' "${os_id}" "${version_id}"
  printf '  - 包管理器：%s\n' "${package_manager}"
  printf '\n'
}

bt_detect_package_manager() {
  if command -v apt-get >/dev/null 2>&1; then
    printf 'apt'
    return
  fi
  if command -v dnf >/dev/null 2>&1; then
    printf 'dnf'
    return
  fi
  if command -v yum >/dev/null 2>&1; then
    printf 'yum'
    return
  fi
  if command -v zypper >/dev/null 2>&1; then
    printf 'zypper'
    return
  fi
  printf '未知'
}

bt_show_disk_overview() {
  if ! command -v lsblk >/dev/null 2>&1; then
    printf '%s未找到 lsblk 命令，无法展示磁盘概览。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return
  fi

  printf '%s磁盘概览（lsblk）:%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
  printf '\n'
}

bt_collect_data_disks() {
  command -v lsblk >/dev/null 2>&1 || return

  lsblk -dnpo NAME,SIZE,TYPE | while read -r disk size type; do
    [[ "${type}" != "disk" ]] && continue
    [[ "${disk}" == /dev/loop* ]] && continue
    [[ "${disk}" == /dev/ram* ]] && continue

    local has_partitions=0
    local has_mounted=0

    while read -r name child_type mountpoint; do
      [[ "${child_type}" != "part" ]] && continue
      has_partitions=1
      [[ -n "${mountpoint}" ]] && has_mounted=1
    done < <(lsblk -nrpo NAME,TYPE,MOUNTPOINT "${disk}")

    ((has_mounted == 1)) && continue

    printf '%s|%s|%d\n' "${disk}" "${size}" "${has_partitions}"
  done
}

bt_select_data_disk() {
  local entries=()
  if ! mapfile -t entries < <(bt_collect_data_disks); then
    entries=()
  fi

  if [[ "${#entries[@]}" -eq 0 ]]; then
    printf '%s未检测到未挂载的数据盘，将直接安装宝塔面板。%s\n\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
    return 1
  fi

  printf '%s检测到以下未挂载的数据盘：%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  local idx entry disk size has_partitions partition_hint
  for idx in "${!entries[@]}"; do
    entry=${entries[idx]}
    IFS='|' read -r disk size has_partitions <<<"${entry}"
    partition_hint="(无分区)"
    if [[ "${has_partitions}" -eq 1 ]]; then
      partition_hint="(已有分区)"
    fi
    printf '  %d) %s %s %s\n' "$((idx + 1))" "${disk}" "${size}" "${partition_hint}"
  done

  printf '%s请选择需要挂载到 /www 的序号（直接回车跳过）：%s' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  local selection
  read -r selection
  if [[ -z "${selection}" ]]; then
    printf '%s已跳过数据盘挂载步骤。%s\n\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
    return 1
  fi
  if ! [[ "${selection}" =~ ^[0-9]+$ ]]; then
    printf '%s输入无效，已跳过数据盘挂载。%s\n\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return 1
  fi

  local index=$((selection - 1))
  if ((index < 0 || index >= ${#entries[@]})); then
    printf '%s序号超出范围，已跳过数据盘挂载。%s\n\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return 1
  fi

  printf '%s' "${entries[index]}"
  return 0
}

bt_prepare_data_disk() {
  local disk=$1
  local size=$2
  local has_partitions=$3

  printf '\n%s即将处理数据盘 %s（容量 %s）。%s\n' "${COLOR_SECONDARY}" "${disk}" "${size}" "${COLOR_RESET}"

  if ((has_partitions == 1)); then
    printf '%s警告：检测到该磁盘已有分区，请确认其中无重要数据。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    lsblk "${disk}"
    printf '%s继续将会清空所有分区并重新格式化，是否继续？ [y/N]: %s' "${COLOR_WARNING}" "${COLOR_RESET}"
    local confirm
    read -r confirm
    if [[ ! "${confirm}" =~ ^[Yy]$ ]]; then
      printf '%s用户取消了磁盘重新分区操作。%s\n\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
      return 1
    fi
  else
    printf '%s该磁盘未检测到现有分区，将创建新的分区并挂载到 /www。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  fi

  if ! bt_require_commands parted mkfs.ext4 blkid; then
    return 1
  fi

  if ! bt_prepare_mountpoint "/www"; then
    return 1
  fi

  bt_partition_disk "${disk}"
  local partition
  partition=$(bt_find_primary_partition "${disk}")
  if [[ -z "${partition}" ]]; then
    printf '%s未能找到新建的分区，请手动检查。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return 1
  fi

  if ! bt_format_partition "${partition}"; then
    return 1
  fi

  if ! bt_mount_partition "${partition}" "/www"; then
    return 1
  fi

  return 0
}

bt_require_commands() {
  local missing=()
  local cmd
  for cmd in "$@"; do
    command -v "${cmd}" >/dev/null 2>&1 || missing+=("${cmd}")
  done

  if [[ "${#missing[@]}" -gt 0 ]]; then
    printf '%s缺少必要命令：%s，请安装后重试。%s\n' "${COLOR_WARNING}" "${missing[*]}" "${COLOR_RESET}"
    return 1
  fi
  return 0
}

bt_prepare_mountpoint() {
  local mountpoint=$1

  if command -v mountpoint >/dev/null 2>&1 && mountpoint -q "${mountpoint}"; then
    printf '%s检测到 %s 已被挂载，请先卸载后重试。%s\n' "${COLOR_WARNING}" "${mountpoint}" "${COLOR_RESET}"
    return 1
  fi

  if [[ -e "${mountpoint}" && ! -d "${mountpoint}" ]]; then
    printf '%s路径 %s 已存在且不是目录，请手动处理后重试。%s\n' "${COLOR_WARNING}" "${mountpoint}" "${COLOR_RESET}"
    return 1
  fi

  if [[ -d "${mountpoint}" ]]; then
    if [[ -n "$(find "${mountpoint}" -mindepth 1 -print -quit 2>/dev/null)" ]]; then
      local backup="${mountpoint}_backup_$(date +%Y%m%d%H%M%S)"
      printf '%s检测到 %s 已包含数据，将把原内容移动到 %s。确认继续？ [y/N]: %s' "${COLOR_WARNING}" "${mountpoint}" "${backup}" "${COLOR_RESET}"
      local answer
      read -r answer
      if [[ ! "${answer}" =~ ^[Yy]$ ]]; then
        printf '%s已放弃自动挂载操作。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
        return 1
      fi
      mv "${mountpoint}" "${backup}"
      printf '%s已将原目录移动到 %s。%s\n' "${COLOR_SECONDARY}" "${backup}" "${COLOR_RESET}"
      mkdir -p "${mountpoint}"
    fi
  else
    mkdir -p "${mountpoint}"
  fi

  return 0
}

bt_partition_disk() {
  local disk=$1

  printf '%s正在重新分区 %s...%s\n' "${COLOR_SECONDARY}" "${disk}" "${COLOR_RESET}"
  parted -s "${disk}" mklabel gpt
  parted -s "${disk}" mkpart primary ext4 1MiB 100%
  if command -v partprobe >/dev/null 2>&1; then
    partprobe "${disk}" || true
  fi
  if command -v udevadm >/dev/null 2>&1; then
    udevadm settle --timeout=10 || true
  else
    sleep 2
  fi
}

bt_find_primary_partition() {
  local disk=$1
  lsblk -nrpo NAME,TYPE "${disk}" | awk '$2 == "part" {print $1; exit}'
}

bt_format_partition() {
  local partition=$1
  printf '%s正在格式化 %s 为 ext4...%s\n' "${COLOR_SECONDARY}" "${partition}" "${COLOR_RESET}"
  mkfs.ext4 -F "${partition}"
}

bt_mount_partition() {
  local partition=$1
  local mountpoint=$2

  printf '%s正在挂载 %s 到 %s...%s\n' "${COLOR_SECONDARY}" "${partition}" "${mountpoint}" "${COLOR_RESET}"
  mount "${partition}" "${mountpoint}"
  chown root:root "${mountpoint}"
  chmod 755 "${mountpoint}"
  bt_update_fstab "${partition}" "${mountpoint}"
  sync
  printf '%s数据盘已挂载完成。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
}

bt_update_fstab() {
  local partition=$1
  local mountpoint=$2
  local uuid=""

  if command -v blkid >/dev/null 2>&1; then
    uuid=$(blkid -s UUID -o value "${partition}" 2>/dev/null || true)
  fi

  if [[ -n "${uuid}" ]]; then
    if grep -Fqs "UUID=${uuid} ${mountpoint} " /etc/fstab || grep -Fqs "UUID=${uuid}" /etc/fstab; then
      return
    fi
    printf 'UUID=%s %s ext4 defaults 0 2\n' "${uuid}" "${mountpoint}" >> /etc/fstab
  else
    if grep -Fqs "${partition} ${mountpoint} " /etc/fstab; then
      return
    fi
    printf '%s %s ext4 defaults 0 2\n' "${partition}" "${mountpoint}" >> /etc/fstab
  fi
}

bt_run_official_install_script() {
  printf '\n%s开始下载并执行官方宝塔安装脚本，请耐心等待...%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
  local install_cmd='if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec'
  if ! bash -c "${install_cmd}"; then
    printf '%s官方安装脚本执行失败，请检查网络连接或安装日志。%s\n' "${COLOR_WARNING}" "${COLOR_RESET}"
    return 1
  fi
  printf '%s宝塔面板安装流程已结束，请根据脚本输出记录面板信息。%s\n' "${COLOR_SECONDARY}" "${COLOR_RESET}"
}
