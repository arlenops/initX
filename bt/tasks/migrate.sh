#!/usr/bin/env bash
#
# 宝塔面板：数据盘迁移流程。

bt_migrate_to_data_disk() {
  bt_show_todo "挂载并迁移宝塔数据" \
    "检测可用数据盘并格式化/挂载到指定路径" \
    "停止宝塔服务，迁移 /www 等数据目录" \
    "更新 fstab 确保重启后自动挂载" \
    "重新启动宝塔并验证数据完整性"
}
