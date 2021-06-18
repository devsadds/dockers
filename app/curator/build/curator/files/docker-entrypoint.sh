#!/bin/bash

sleep_delay="${SLEEP_DELAY:-24h}"
while true
do
  /usr/bin/curator --config /etc/curator/config_file.yml /etc/curator/action_file.yml; || echo "Warning during /usr/bin/curator --config /etc/curator/config_file.yml /etc/curator/action_file.yml;"
  echo "Sleeping  ${sleep_delay}"
  sleep ${sleep_delay}
done