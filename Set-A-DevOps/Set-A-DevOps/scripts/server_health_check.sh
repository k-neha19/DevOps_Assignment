#!/bin/bash

# Server Health Monitoring Script

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80

# Configuration
SERVICE_NAME="cron"
APP_PORT=8080

# Overall status
FAILED=0

echo "======================================"
echo "       SERVER HEALTH MONITOR"
echo "======================================"

# 1. CPU Utilization
read cpu user nice system idle iowait irq softirq steal rest < /proc/stat
IDLE1=$((idle + iowait))
TOTAL1=$((user + nice + system + idle + iowait + irq + softirq + steal))

sleep 1

read cpu user nice system idle iowait irq softirq steal rest < /proc/stat
IDLE2=$((idle + iowait))
TOTAL2=$((user + nice + system + idle + iowait + irq + softirq + steal))

TOTAL_DIFF=$((TOTAL2 - TOTAL1))
IDLE_DIFF=$((IDLE2 - IDLE1))

if [ "$TOTAL_DIFF" -gt 0 ]; then
    CPU_USAGE=$((100 * (TOTAL_DIFF - IDLE_DIFF) / TOTAL_DIFF))
else
    CPU_USAGE=0
fi

echo "CPU Usage: ${CPU_USAGE}%"
if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
    echo "Status: CRITICAL"
    FAILED=1
else
    echo "Status: PASS"
fi

# 2. Memory Utilization
MEMORY_USAGE=$(free | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')

echo "Memory Usage: ${MEMORY_USAGE}%"
if [ "$MEMORY_USAGE" -ge "$MEMORY_THRESHOLD" ]; then
    echo "Status: CRITICAL"
    FAILED=1
else
    echo "Status: PASS"
fi

# 3. Disk Utilization
DISK_USAGE=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')

echo "Disk Usage: ${DISK_USAGE}%"
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
    echo "Status: CRITICAL"
    FAILED=1
else
    echo "Status: PASS"
fi

# 4. Service Availability
echo "Checking Service: $SERVICE_NAME"

if systemctl is-active --quiet "$SERVICE_NAME"; then
    echo "Service Status: RUNNING - PASS"
else
    echo "Service Status: NOT RUNNING - CRITICAL"
    FAILED=1
fi

# 5. Application Port Check
echo "Checking Application Port: $APP_PORT"

if ss -ltn | awk '{print $4}' | grep -Eq "[:.]${APP_PORT}$"; then
    echo "Port Status: LISTENING - PASS"
else
    echo "Port Status: NOT LISTENING - CRITICAL"
    FAILED=1
fi

echo "======================================"

if [ "$FAILED" -eq 0 ]; then
    echo "OVERALL STATUS: HEALTHY"
    exit 0
else
    echo "OVERALL STATUS: UNHEALTHY"
    exit 1
fi
