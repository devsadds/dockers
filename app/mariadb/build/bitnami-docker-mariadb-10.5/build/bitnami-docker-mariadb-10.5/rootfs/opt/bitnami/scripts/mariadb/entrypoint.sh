#!/bin/bash

# shellcheck disable=SC1091
export ipaddr=$(ifconfig "${SERVER_INTERFACE_BIND:-eth0}" | grep 'inet' | awk '{print $2}')
export hostname=$(hostname)
export tags="[$tags]"
progress-bar() {
  local duration=${1}


    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }
    clean_line() { printf "\r"; }

  for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
      already_done; remaining; percentage
      sleep 1
      clean_line
  done
  clean_line
}
func_consul_agent_start(){
  echo "Begin func ${FUNCNAME[0]}" 
  echo "{ \"services\": [ { \"name\": \"${CONSUL_SERVICE:-mariadb-10-5}\", \"address\": \"$ipaddr\", \"port\": 3306, \"Tags\": $tags, \"checks\": [ { \"name\": \"check if mysql port is open\", \"tcp\": \"$ipaddr:3306\", \"interval\": \"10s\", \"timeout\": \"5s\" } ] } ] }" > /tmp/mysql.json

  sleep 1;
  echo "show /tmp/mysql.json"
  echo "------------------------------------"
  cat /tmp/mysql.json
  echo "------------------------------------"
# Starting consul client
  echo "------------------------------------"
  echo "exec /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node ${SERVER_NAME:-db}-${hostname} -data-dir /tmp -config-format json -config-file /tmp/mysql.json &"
  echo "------------------------------------"
  echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-5s} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-5s}
  if [[ $(ps aux | grep "consul.*agent" | grep -ve 'grep') == "" ]];then
      /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node ${SERVER_NAME:-db}-${hostname} -data-dir /tmp -config-file /tmp/mysql.json 2>&1 & disown;
      echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-5s} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-5s}
  else
      echo "consul agent already running"
  fi

  echo "End func ${FUNCNAME[0]}" 
}
func_consul_agent_start

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load libraries
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libmariadb.sh

# Load MariaDB environment variables
. /opt/bitnami/scripts/mariadb-env.sh

print_welcome_page

if [[ "$1" = "/opt/bitnami/scripts/mariadb/run.sh" ]]; then
    info "** Starting MariaDB setup **"
    /opt/bitnami/scripts/mariadb/setup.sh
    info "** MariaDB setup finished! **"
fi

echo ""

exec "$@"
