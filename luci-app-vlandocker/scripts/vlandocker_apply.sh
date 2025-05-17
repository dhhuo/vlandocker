#!/bin/bash
CONFIG_FILE="$1"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "配置文件不存在！"
  exit 1
fi

read IFACE < "$CONFIG_FILE"

VLAN_IDS=()
VLAN_NETS=()

tail -n +2 "$CONFIG_FILE" | while read vlan subnet; do
  VLAN_IDS+=("$vlan")
  VLAN_NETS+=("$subnet")
done

# 兼容 /bin/sh, 重新读取一次到变量
VLAN_IDS=()
VLAN_NETS=()
tail -n +2 "$CONFIG_FILE" | while read vlan subnet; do
  VLAN_IDS+=("$vlan")
  VLAN_NETS+=("$subnet")
done

# 组装参数字符串
ARGS="$IFACE"
for v in "${VLAN_IDS[@]}"; do ARGS="$ARGS $v"; done
for n in "${VLAN_NETS[@]}"; do ARGS="$ARGS $n"; done

/usr/bin/setup_vlan_docker_with_dhcp.sh $ARGS
