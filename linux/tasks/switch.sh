#!/usr/bin/env bash
#
# Linux 安装源切换任务。

linux_switch_mirror() {
  linux_show_todo "Linux 安装源切换" \
    "识别发行版与版本号" \
    "备份现有 sources.list 或 repo 配置" \
    "写入自定义镜像源并刷新缓存" \
    "提供验证命令，例如 apt update 或 yum makecache"
}
