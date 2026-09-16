#!/bin/bash

case "$1" in
    gpu)
        usage=$(cat /sys/class/drm/card1/device/gpu_busy_percent 2>/dev/null || echo "N/A")
        echo "{\"text\":\"󰢮  ${usage}%\"}"
        ;;
esac
