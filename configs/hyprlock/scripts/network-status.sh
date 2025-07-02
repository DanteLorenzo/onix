#!/bin/bash
IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
if [ -n "$IFACE" ]; then
  SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
  echo "${SSID:-Connected}"
else
  echo "Offline"
fi
