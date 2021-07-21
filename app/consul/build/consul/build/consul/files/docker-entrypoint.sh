#!/bin/bash

app_prepare(){


if [ "${CONSUL_SERVER_CLUSTER_SIZE}" ];then
  echo "Run consul server as bootstap node"
  cat <<OEF> /consul/config/config.json
{
  "advertise_addr" : "{{ GetInterfaceIP \"${CONSUL_SERVER_INTERFACE_BIND:-eth0}\" }}",
  "bind_addr": "{{ GetInterfaceIP \"${CONSUL_SERVER_INTERFACE_BIND:-eth0}\" }}",
  "client_addr": "0.0.0.0",
  "data_dir": "/consul/data",
  "datacenter": "${CONSUL_SERVER_DATACENTER:-dc1}",
  "server" : true,
  "acl": {
    "enabled": ${CONSUL_ACL_ENABLED:-true},
    "default_policy": ${CONSUL_ACL_DEFAULT_POLICY:-allow},
    "enable_token_persistence": ${CONSUL_ACL_ENABLE_TOKEN_PERSISTENCE:-true},
    "down_policy": "extend-cache",
    "tokens": {
      "agent": "${CONSUL_ACL_TOKENS_AGENT:-change_me}",
      "agent_master": "${CONSUL_ACL_TOKENS_AGENT_MASTER:-change_me}",
      "default": "${CONSUL_ACL_TOKENS_DEFAULT:-change_me}"
    }
  }, 
  "server_name" : "${CONSUL_SERVER_NAME:-server-bootstrap.service.consul}",
  "skip_leave_on_interrupt" : true,
  "leave_on_terminate" : true,
  "bootstrap": ${CONSUL_SERVER_BOOTSTRAP:-true},
  "ui_config": {
    "enabled": true
  },
  "addresses" : {
    "http": "0.0.0.0",
    "dns":  "0.0.0.0",
    "https": "0.0.0.0",
    "grpc": "0.0.0.0"
  },
  "ports" : {
    "server": 8300,
    "http": 8500,
    "dns": 8600
  },
  "autopilot": {
    "cleanup_dead_servers": ${CONSUL_CLEANUP_DEAD_SERVERS:-true},
    "last_contact_threshold": "1s",
    "max_trailing_logs": 500
  },
  "disable_update_check": true,
  "log_level": "${CONSUL_SERVER_LOG_LEVEL:-warn}"
}

OEF

else
  echo "Run consul server as join node"
  cat <<OEF> /consul/config/config.json

{
  "advertise_addr" : "{{ GetInterfaceIP \"${CONSUL_SERVER_INTERFACE_BIND:-eth0}\" }}",
  "bind_addr": "{{ GetInterfaceIP \"${CONSUL_SERVER_INTERFACE_BIND:-eth0}\" }}",
  "client_addr": "0.0.0.0",
  "data_dir": "/consul/data",
  "datacenter": "${CONSUL_SERVER_DATACENTER:-dc1}",
  "server" : true,
  "retry_join" : [
    "${CONSUL_SERVER_NETWORK_REJOIN_HOST:-consul}"
  ],
  "acl": {
    "enabled": ${CONSUL_ACL_ENABLED:-true},
    "default_policy": ${CONSUL_ACL_DEFAULT_POLICY:-allow},
    "enable_token_persistence": ${CONSUL_ACL_ENABLE_TOKEN_PERSISTENCE:-true},
    "down_policy": "extend-cache",
    "tokens": {
      "agent": "${CONSUL_ACL_TOKENS_AGENT:-change_me}",
      "agent_master": "${CONSUL_ACL_TOKENS_AGENT_MASTER:-change_me}",
      "default": "${CONSUL_ACL_TOKENS_DEFAULT:-change_me}"
    }
  }, 
  "server_name" : "${CONSUL_SERVER_NAME:-pxc.service.consul}",
  "skip_leave_on_interrupt" : true,
  "leave_on_terminate" : true,
  "ui_config": {
    "enabled": true
  },
  "addresses" : {
    "http": "0.0.0.0",
    "dns":  "0.0.0.0",
    "https": "0.0.0.0",
    "grpc": "0.0.0.0"
  },
  "ports" : {
    "server": 8300,
    "http": 8500,
    "dns": 8600
  },
  "autopilot": {
  	"cleanup_dead_servers": ${CONSUL_CLEANUP_DEAD_SERVERS:-true},
  	"last_contact_threshold": "1s",
  	"max_trailing_logs": 500
  	},
  	"disable_update_check": true,
  	"log_level": "${CONSUL_SERVER_LOG_LEVEL:-warn}",
  	"connect": {"
  	"enabled": true
  }
}

OEF

fi

}

app_run(){
	echo "Run consul agent -config-file /consul/config/config.json"
	echo "Config agent"
	echo "------------"
	cat /consul/config/config.json
	echo "------------"
	consul agent -config-file /consul/config/config.json
}

main(){
	app_prepare
	app_run
}

main