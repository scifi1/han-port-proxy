#!/usr/bin/env bash

"${ADDON_NAME:=power_meter}"

BASE_DIR="/data/addon_config"
TARGET_DIR="${BASE_DIR}/${ADDON_NAME}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "[INFO] Creating config dir: $TARGET_DIR"
  mkdir -p "$TARGET_DIR"
fi

CONFIG_PATH=/${TARGET_DIR}/options.yaml

MQTT_HOST=$(jq -r '.mqtt_host' $CONFIG_PATH)
MQTT_PREFIX=$(jq -r '.mqtt_prefix' $CONFIG_PATH)
MQTT_RETURN_PREFIX=$(jq -r '.mqtt_rprefix' $CONFIG_PATH)
MQTT_PORT=$(jq -r '.mqtt_port' $CONFIG_PATH)
MQTT_USERNAME=$(jq -r '.mqtt_username' $CONFIG_PATH)
MQTT_PASSWORD=$(jq -r '.mqtt_password' $CONFIG_PATH)
DEVICE_NAME=$(jq -r '.device_name' $CONFIG_PATH)
DEVICE_ID=$(jq -r '.device_id' $CONFIG_PATH)


export MQTT_HOST MQTT_PREFIX DEVICE_NAME DEVICE_ID

echo "[INFO] Starting with:"
echo "MQTT_HOST=$MQTT_HOST"
echo "PREFIX=$MQTT_PREFIX"

while true; do
  /hanport_power_meter.sh
  echo "[WARN] Restarting in 5s..."
  sleep 5
done