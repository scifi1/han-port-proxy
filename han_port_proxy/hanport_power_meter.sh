#!/usr/bin/env bash


RAW_TOPIC="han/raw"

MQTT_OPTIONS=" -h ${MQTT_HOST} -u ${MQTT_USERNAME} -p ${MQTT_PORT} -P ${MQTT_PASSWORD}"

declare -A CREATED

# =========================
# FRIENDLY NAME MAPPING
# =========================
declare -A NAME_MAP
declare -A KEY_MAP

NAME_MAP["1-0:1.7.0"]="Effekt"
KEY_MAP["1-0:1.7.0"]="power"

NAME_MAP["1-0:2.7.0"]="Export Effekt"
KEY_MAP["1-0:2.7.0"]="power_export"

NAME_MAP["1-0:1.8.0"]="Energi import"
KEY_MAP["1-0:1.8.0"]="energy_import"

NAME_MAP["1-0:2.8.0"]="Energi export"
KEY_MAP["1-0:2.8.0"]="energy_export"

NAME_MAP["1-0:32.7.0"]="Spänning L1"
KEY_MAP["1-0:32.7.0"]="voltage_l1"

NAME_MAP["1-0:52.7.0"]="Spänning L2"
KEY_MAP["1-0:52.7.0"]="voltage_l2"

NAME_MAP["1-0:72.7.0"]="Spänning L3"
KEY_MAP["1-0:72.7.0"]="voltage_l3"

NAME_MAP["1-0:31.7.0"]="Ström L1"
KEY_MAP["1-0:31.7.0"]="current_l1"

NAME_MAP["1-0:51.7.0"]="Ström L2"
KEY_MAP["1-0:51.7.0"]="current_l2"

NAME_MAP["1-0:71.7.0"]="Ström L3"
KEY_MAP["1-0:71.7.0"]="current_l3"

# =========================

normalize_obis() {
  echo "$1" | sed 's/[-:.]/_/g'
}

guess_device_class() {
  case "$1" in
    kW) echo "power" ;;
    kWh) echo "energy" ;;
    V) echo "voltage" ;;
    A) echo "current" ;;
    kvar) echo "reactive_power" ;;
    kvarh) echo "energy" ;;
    *) echo "" ;;
  esac
}

guess_state_class() {
  case "$1" in
    kWh|kvarh) echo "total_increasing" ;;
    *) echo "measurement" ;;
  esac
}

get_name_and_key() {
  local obis="$1"

  if [[ -n "${NAME_MAP[$obis]}" ]]; then
    NAME="${NAME_MAP[$obis]}"
    KEY="${KEY_MAP[$obis]}"
  else
    NAME="$obis"
    KEY=$(normalize_obis "$obis")
  fi
}

publish_discovery() {
  local obis="$1"
  local key="$2"
  local name="$3"
  local unit="$4"

  local device_class
  device_class=$(guess_device_class "$unit")

  local state_class
  state_class=$(guess_state_class "$unit")

  echo "[DISCOVERY] $name ($key)"

  mosquitto_pub -r ${MQTT_OPTIONS} \
    -t "homeassistant/sensor/${DEVICE_ID}_${key}/config" \
    -m "{
      \"name\": \"$name\",
      \"state_topic\": \"$MQTT_PREFIX/$key\",
      \"unit_of_measurement\": \"$unit\",
      \"unique_id\": \"${DEVICE_ID}_${key}\",
      \"state_class\": \"$state_class\",
      \"device_class\": \"$device_class\",
      \"device\": {
        \"identifiers\": [\"$DEVICE_ID\"],
        \"name\": \"$DEVICE_NAME\",
        \"manufacturer\": \"HAN\",
        \"model\": \"DLMS Meter\"
      }
    }"
}

echo "[INFO] Listening on $RAW_TOPIC..."

mosquitto_sub ${MQTT_OPTIONS} -t "$RAW_TOPIC" | while read -r line
do
  if [[ $line =~ ([0-9]-[0-9]:[0-9]+\.[0-9]+\.[0-9]+)\(([0-9.]+)\*?([A-Za-z]+)?\) ]]; then  

    OBIS="${BASH_REMATCH[1]}"
    VALUE="${BASH_REMATCH[2]}"
    UNIT="${BASH_REMATCH[3]}"

    get_name_and_key "$OBIS"

    if [[ -z "${CREATED[$KEY]}" ]]; then
      publish_discovery "$OBIS" "$KEY" "$NAME" "$UNIT"
      CREATED[$KEY]=1
    fi

    mosquitto_pub ${MQTT_OPTIONS} -t "${MQTT_PREFIX}/${KEY}" -m "${VALUE}"
  fi
