#!/usr/bin/env bash

function get_volume {
    pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | sed 's/%//'
}

function is_mute {
    pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'
}

function get_device {
    pactl get-default-sink | awk -F '.' '{print $4}'
}

volume=$(get_volume)
mute=$(is_mute)
device=$(get_device)

if [[ "$mute" == "yes" ]]; then
    echo "{\"class\": \"muted\", \"percentage\": $volume, \"device\": \"$device\"}"
else
    echo "{\"class\": \"unmuted\", \"percentage\": $volume, \"device\": \"$device\"}"
fi