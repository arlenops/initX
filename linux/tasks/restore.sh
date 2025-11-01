#!/usr/bin/env bash
#
# Linux 官方源恢复任务。

linux_restore_official_sources() {
  linux_show_todo "恢复官方软件源" \
    "检测当前镜像设置并生成官方配置" \
    "恢复备份或重新生成官方源文件" \
    "清理临时文件并刷新软件包缓存" \
    "记录操作日志方便审计"
}
