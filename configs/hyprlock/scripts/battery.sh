#!/bin/bash
upower -i /org/freedesktop/UPower/devices/battery_BAT0 2>/dev/null \
  | grep --color=never -E "percentage" \
  | awk '{print $2}' || echo "AC"
