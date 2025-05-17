#!/bin/bash
set -e

IFACE="$1"
shift

VLAN_IDS=()
while [ "$1" ] && [[ "$1" =~ ^[0-9]+$ ]]; do
  VLAN_IDS+=("$1")
  shift
done

VLAN_NETS=("$@")

if [ "${#VLAN_IDS[@]}" -eq 0 ] || [ "${#VLAN_IDS[@]}" -ne "${#VLAN_NETS[@]}" ]; then
  echo "Usage: $0 <iface> <vlan_id1> [vlan_id2 ...] <subnet1> [subnet2 ...]"
  exit 1
fi

echo "接口: $IFACE"
echo "VLAN IDs: ${VLAN_IDS[*]}"
echo "子网: ${VLAN_NETS[*]}"

# 配置 VLAN
for VLAN_ID in "${VLAN_IDS[@]}"; do
  uci -q delete network.eth${IFACE}.${VLAN_ID}
  uci -q delete network.vlan${VLAN_ID}
done

for i in "${!VLAN_IDS[@]}"; do
  VLAN_ID="${VLAN_IDS[$i]}"
  IPADDR="${VLAN_NETS[$i]}"
  echo "[+] 配置 VLAN $VLAN_ID，IP $IPADDR"

  uci set network.eth${IFACE}.${VLAN_ID}="device"
  uci set network.eth${IFACE}.${VLAN_ID}.name="${IFACE}.${VLAN_ID}"
  uci set network.eth${IFACE}.${VLAN_ID}.type='8021q'
  uci set network.eth${IFACE}.${VLAN_ID}.ifname="$IFACE"
  uci set network.eth${IFACE}.${VLAN_ID}.vid="$VLAN_ID"

  uci set network.vlan${VLAN_ID}="interface"
  uci set network.vlan${VLAN_ID}.proto='static'
  uci set network.vlan${VLAN_ID}.device="${IFACE}.${VLAN_ID}"
  uci set network.vlan${VLAN_ID}.ipaddr="${IPADDR%/*}"
  uci set network.vlan${VLAN_ID}.netmask='255.255.255.0'
done

uci commit network
/etc/init.d/network reload

# 配置 DHCP
for VLAN_ID in "${VLAN_IDS[@]}"; do
  uci -q delete dhcp.vlan${VLAN_ID}
done

for i in "${!VLAN_IDS[@]}"; do
  VLAN_ID="${VLAN_IDS[$i]}"
  IPADDR="${VLAN_NETS[$i]}"
  SUBNET="${IPADDR%.*}"
  echo "[+] 配置 DHCP vlan$VLAN_ID，网段 $SUBNET.0/24"

  uci set dhcp.vlan${VLAN_ID}="dhcp"
  uci set dhcp.vlan${VLAN_ID}.interface="vlan${VLAN_ID}"
  uci set dhcp.vlan${VLAN_ID}.start=100
  uci set dhcp.vlan${VLAN_ID}.limit=150
  uci set dhcp.vlan${VLAN_ID}.leasetime="12h"
  uci set dhcp.vlan${VLAN_ID}.dhcp_option="3,$SUBNET.1"
done

uci commit dhcp
/etc/init.d/dnsmasq restart

# 创建 Docker macvlan 网络
for i in "${!VLAN_IDS[@]}"; do
  VLAN_ID="${VLAN_IDS[$i]}"
  SUBNET="${VLAN_NETS[$i]}"
  GATEWAY="${SUBNET%.*}.1"
  NETWORK_NAME="vlan${VLAN_ID}_docker"
  MACVLAN_IF="${IFACE}.${VLAN_ID}"

  echo "[+] 创建 Docker macvlan 网络 $NETWORK_NAME..."

  docker network rm $NETWORK_NAME 2>/dev/null || true

  docker network create -d macvlan     --subnet=$SUBNET     --gateway=$GATEWAY     --ipv6=false     -o parent=$MACVLAN_IF     $NETWORK_NAME
done

echo "[✔] VLAN + DHCP + Docker 网络配置完成"
