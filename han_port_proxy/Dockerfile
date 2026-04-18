FROM alpine:3.20

RUN apk add --no-cache bash mosquitto-clients jq

COPY run.sh /run.sh
COPY hanport_power_meter.sh /hanport_power_meter.sh

RUN chmod +x /run.sh /hanport_power_meter.sh

CMD ["/run.sh"]
