{
  "advertise_addr" : "{{ GetInterfaceIP \"eth0\" }}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "client_addr": "0.0.0.0",
  "data_dir": "/consul/data",
  "datacenter": "dc1",
  "server" : true,
  "retry_join" : [
    "server-bootstrap"
  ],
  "acl_default_policy":"allow",
  "acl_down_policy":"extend-cache",
  "server_name" : "pxc.service.consul",
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
    "cleanup_dead_servers": true,
    "last_contact_threshold": "1s",
    "max_trailing_logs": 500
  },
  "disable_update_check": true,
  "log_level": "warn"
}


  { 
  "advertise_addr" : "{{ GetInterfaceIP \"eth0\" }}",
  "bind_addr": "{{ GetInterfaceIP \"eth0\" }}",
  "bootstrap": false,
  "server":true,
  "skip_leave_on_interrupt": true,
  "server_name" : "main.service.consul",
  "datacenter":"dc1",
  "data_dir":"/consul/data",
  "log_level": "DEBUG",
  "acl": {
    "enabled": true,
    "default_policy": "deny",
    "enable_token_persistence": true,
    "down_policy": "extend-cache",
    "tokens": {
      "agent": "02fba508-f766-dd6e-e94b-dd2f5404386f"
    }
  }, 
  "