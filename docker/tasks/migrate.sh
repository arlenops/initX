#!/usr/bin/env bash
#
# Docker 数据盘迁移任务。

docker_migrate_to_data_disk() {
  docker_show_todo "Docker 数据盘迁移" \
    "检测数据盘并准备挂载目录" \
    "停止 Docker 服务并移动 /var/lib/docker" \
    "创建软链接或修改 --data-root 设置" \
    "重启服务并执行 docker info 验证"
}
