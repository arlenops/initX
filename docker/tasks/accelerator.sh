#!/usr/bin/env bash
#
# Docker 加速源切换任务。

docker_switch_accelerator() {
  docker_show_todo "Docker 加速源切换" \
    "检测当前发行版与 Docker 版本" \
    "备份 /etc/docker/daemon.json 配置" \
    "写入国内镜像站点并重启 Docker" \
    "验证拉取速度或打印测试命令"
}
