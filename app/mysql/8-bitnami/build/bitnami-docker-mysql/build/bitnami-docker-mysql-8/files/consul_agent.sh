#!/bin/bash
ipaddr=$(ifconfig "${SERVER_INTERFACE_BIND:-eth0}" | grep 'inet' | awk '{print $2}')
hostname=$(hostname)
tags=$(echo "{ \"service\": \"${SERVER_NAME:-db}\" }")
tags="[$tags]"

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
  echo "{ \"services\": [ { \"name\": \"${CONSUL_SERVICE:-mysql-8}\", \"address\": \"$ipaddr\", \"port\": 3306,  \"checks\": [ { \"name\": \"check if mysql port is open\", \"tcp\": \"$ipaddr:3306\", \"interval\": \"10s\", \"timeout\": \"5s\" } ] } ] }" > ${CONSUL_AGENT_DIR:-/consul_agent}/mysql.json

  sleep 1;
  echo "show ${CONSUL_AGENT_DIR:-/consul_agent}/mysql.json"
  echo "------------------------------------"
  cat ${CONSUL_AGENT_DIR:-/consul_agent}/mysql.json
  echo "------------------------------------"
# Starting consul client
  echo "------------------------------------"
  echo "exec /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node ${SERVER_NAME:-db}-${hostname} -data-dir ${CONSUL_AGENT_DIR:-/consul_agent} -config-format json -config-file ${CONSUL_AGENT_DIR:-/consul_agent}/mysql.json &"
  echo "------------------------------------"
  echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-5s} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-5s}
  if [[ $(ps aux | grep "consul.*agent" | grep -ve 'grep\|consul_agent') == "" ]];then
      echo "Start consul agent"
      /bin/consul agent -retry-join $DISCOVERY_SERVICE -client 0.0.0.0 -bind $ipaddr -node ${SERVER_NAME:-db}-${hostname} -data-dir ${CONSUL_AGENT_DIR:-/consul_agent} -config-file ${CONSUL_AGENT_DIR:-/consul_agent}/mysql.json 2>&1 & disown;
      echo "Sleep for ${CONSUL_AGENT_SLEEP_TIME:-5s} seconds after agent start" && progress-bar ${CONSUL_AGENT_SLEEP_TIME:-5s}
  else
      echo "consul agent already running Status=$(ps aux | grep "consul.*agent" | grep -ve 'grep')"
  fi

  echo "End func ${FUNCNAME[0]}" 
}


main(){
  func_consul_agent_start
}

main
