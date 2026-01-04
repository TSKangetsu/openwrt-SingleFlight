#!/bin/sh

# 定义无线配置文件路径
WIRELESS_CONFIG="/etc/config/wireless"

# 检查参数
if [ -z "$1" ]; then
    echo "用法: $0 [enable|disable]"
    exit 1
fi

ACTION="$1"

# 根据动作修改配置文件并重启无线
case "$ACTION" in
    enable)
        echo "启用无线AP..."
        uci set wireless.radio0.disabled='0'
        uci commit wireless
        wifi reload
        echo "无线AP已启用。"
        ;;
    disable)
        echo "禁用无线AP..."
        uci set wireless.radio0.disabled='1'
        uci commit wireless
        wifi reload
        echo "无线AP已禁用。"
        ;;
    *)
        echo "无效的参数: $ACTION"
        echo "用法: $0 [enable|disable]"
        exit 1
        ;;
esac

exit 0