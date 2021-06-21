#!/bin/bash
set -e

ipaddr=$(ifconfig "${SERVER_INTERFACE_BIND:-eth0}" | grep 'inet' | awk '{print $2}')
hostname=$(hostname)
exec_prefix=$(whoami)
haproxy_user="${HAPROXY_USER:-root}"

if [[ "${exec_prefix}" == "root" ]];then
	exec_prefix=""
else
	exec_prefix="sudo"
fi

prepare(){
	echo "Run from user $(whoami) .exec_prefix is ${exec_prefix}"
	${exec_prefix} echo "Exec funct echo ${FUNCNAME[0]}"
	if [[ ! -d "/opt/consul-template/templates" ]];then
		mkdir -p /opt/consul-template/templates
	fi
	if [[ ! -d "/etc/supervisor/conf.d" ]];then
		mkdir -p /etc/supervisor/conf.d
	fi
	if [[ ! -d "/docker-run.d" ]];then
		mkdir -p /docker-run.d
	fi
	if [[ ! -d "/usr/share/haproxy" ]];then
		mkdir -p /usr/share/haproxy
		chown -R ${haproxy_user}:${haproxy_user} /usr/share/haproxy
	fi	
	if [[ ! -f "/tmp/haproxy.log" ]];then
		touch /tmp/haproxy.log
		chown -R ${haproxy_user}:${haproxy_user} /tmp/haproxy.log
	fi
	consul_template_gen_haproxy
}


consul_template_gen_haproxy(){
	${exec_prefix} cat << OEF > /opt/consul-template/templates/haproxy.ctmpl

global
	##log to stderr
	log stdout  format raw  local0  ${HAPROXY_LOG_LEVEL:-info}
	maxconn ${HAPROXY_OPT_MAXCONN:-500}
	chroot /usr/share/haproxy
	pidfile  /usr/share/haproxy/haproxy.pid
	user ${haproxy_user}
	group ${haproxy_user}
    stats socket ipv4@127.0.0.1:9999 level admin
    stats socket /usr/share/haproxy/hapee-lb.sock mode 666 level admin
    stats timeout 2m
    #daemon
resolvers consul
  	nameserver consul localhost:8600
  	accepted_payload_size 8192


defaults
	mode http
	log global
	option tcplog
	#option httplog
	option dontlognull
	retries 3
	option redispatch
	maxconn ${HAPROXY_OPT_MAXCONN:-500}
    timeout client  ${HAPROXY_TIMEOUT_CLIENT:-220s}
    timeout server  ${HAPROXY_TIMEOUT_SERVER:-220s}
    timeout connect ${HAPROXY_TIMEOUT_CONNECT:-220s}
frontend writer-front
	bind *:5432
	mode tcp
	default_backend writer-back
	acl white_list src ${HAPROXY_SERVICE_ALLOW_HOSTS:-10.0.0.0/8 172.0.0.0/8 127.0.0.1/32}
	tcp-request content accept if white_list
	tcp-request content reject	
    timeout client  ${HAPROXY_TIMEOUT_CLIENT:-220s}
frontend reader-front
	bind *:5433
	mode tcp
	default_backend reader-back
	acl white_list src ${HAPROXY_SERVICE_ALLOW_HOSTS:-10.0.0.0/8 172.0.0.0/8 127.0.0.1/32}
	tcp-request content accept if white_list
	tcp-request content reject
    timeout client  ${HAPROXY_TIMEOUT_CLIENT:-220s}
frontend stats-front
	bind *:80
	mode http
	default_backend stats-back
	acl white_list src ${HAPROXY_STATS_ALLOW_HOSTS:-10.0.0.0/8 172.0.0.0/8 127.0.0.1/32}
	tcp-request content accept if white_list
	tcp-request content reject	
frontend exporter-front
	bind *:9101
	mode http
	default_backend exporter-back
	acl white_list src ${HAPROXY_STATS_ALLOW_HOSTS:-10.0.0.0/8 172.0.0.0/8 127.0.0.1/32}
	tcp-request content accept if white_list
	tcp-request content reject	


backend writer-back
	mode tcp
	option tcpka
	balance leastconn
    timeout server  ${HAPROXY_TIMEOUT_SERVER:-220s}
    timeout connect ${HAPROXY_TIMEOUT_CONNECT:-220s}
	option pgsql-check user ${HAPROXY_POSTGRES_CHECK_USER:-postgres}
{{range \$index, \$element := service "${DISCOVERY_SERVICE_NAME_POSTGRES_WRITER:-postgres-12-repmgr}"}}
{{if .Tags | contains "master"}}
	server ${DISCOVERY_SERVICE_NAME_POSTGRES_WRITER:-postgres-12-repmgr}_writer-{{.Node}} {{.Address}}:{{.Port}} check port {{.Port}} maxconn ${HAPROXY_POSTGRES_BACKEND_MAX_CONN:-100}{{end}}
{{end}}
{{range \$index, \$element := service "${DISCOVERY_SERVICE_NAME_POSTGRES_READER:-postgres-12-repmgr}"}}
{{if .Tags | contains "standby"}}
	server ${DISCOVERY_SERVICE_NAME_POSTGRES_READER:-postgres-12-repmgr}_reader-{{.Node}} {{.Address}}:{{.Port}} backup check port {{.Port}} maxconn ${HAPROXY_POSTGRES_BACKEND_MAX_CONN:-100}{{end}}
{{end}}

backend reader-back
	balance leastconn
	mode tcp
	option tcpka
    timeout server  ${HAPROXY_TIMEOUT_SERVER:-220s}
    timeout connect ${HAPROXY_TIMEOUT_CONNECT:-220s}
	option pgsql-check user ${HAPROXY_POSTGRES_CHECK_USER:-postgres}
{{range \$index, \$element := service "${DISCOVERY_SERVICE_NAME_POSTGRES_READER:-postgres-12-repmgr}"}}
{{if .Tags | contains "standby"}}
	server ${DISCOVERY_SERVICE_NAME_POSTGRES_READER:-postgres-12-repmgr}_reader-{{.Node}} {{.Address}}:{{.Port}} check port {{.Port}} maxconn ${HAPROXY_POSTGRES_BACKEND_MAX_CONN:-100}{{end}}
{{end}}
{{range \$index, \$element := service "${DISCOVERY_SERVICE_NAME_POSTGRES_WRITER:-postgres-12-repmgr}"}}
{{if .Tags | contains "master"}}
	server ${DISCOVERY_SERVICE_NAME_POSTGRES_WRITER:-postgres-12-repmgr}_reader_backup-{{.Node}} {{.Address}}:{{.Port}} backup check port {{.Port}} maxconn ${HAPROXY_POSTGRES_BACKEND_MAX_CONN:-100}{{end}}  
{{end}}

backend stats-back
	mode http
	balance roundrobin
	stats uri ${HAPROXY_STATS_URL:-/haproxy/stats}
	stats auth ${HAPROXY_STATS_AUTH_USER:-haproxyuser1}:${HAPROXY_STATS_AUTH_PASSWORD:-haproxyuser1PASSWORD}

backend exporter-back
   mode http
   timeout server 1h
   timeout connect 5s  
   option http-pretend-keepalive
   server server1 localhost:19101 weight 1 maxconn 1024 check	
OEF
}


s_consul_agent(){
	${exec_prefix} echo "Exec funct echo ${FUNCNAME[0]}"
	${exec_prefix} echo "{ \"services\": [ { \"name\": \"${DOCKER_ROLE}\", \"address\": \"$ipaddr\", \"port\": 5432 } ] }" > /docker-run.d/${DOCKER_ROLE}.json
	${exec_prefix} cat << OEF > /etc/supervisor/conf.d/${FUNCNAME[0]}.conf
[supervisord]
nodaemon=true
logfile=/dev/null


[program:${FUNCNAME[0]}]
command=/bin/consul agent -retry-join $DISCOVERY_SERVICE_HOST -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /docker-run.d -config-file /docker-run.d/${DOCKER_ROLE}.json
exitcodes=0,2
stopsignal=SIGTERM
stopwaitsecs=5
stopasgroup=false
killasgroup=false
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
startretries=100
OEF
}


s_consul_template(){
	${exec_prefix} echo "Exec funct echo ${FUNCNAME[0]}"
	${exec_prefix} cat << OEF > /etc/supervisor/conf.d/${FUNCNAME[0]}.conf
[supervisord]
nodaemon=true
logfile=/dev/null

[program:${FUNCNAME[0]}]
command=/usr/local/bin/consul-template -config=/opt/consul-template/config/consul-template-${DOCKER_ROLE}.cfg
exitcodes=0,2
stopsignal=SIGTERM
stopwaitsecs=5
stopasgroup=false
killasgroup=false
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
startretries=100
OEF
}


s_harpoxy(){
	${exec_prefix} cat << OEF > /etc/supervisor/conf.d/haproxy.conf

[supervisord]
nodaemon=true
logfile=/dev/null


[program:haproxy]
command=/usr/local/sbin/haproxy  -f /etc/haproxy/haproxy.conf
exitcodes=0,2
stopsignal=QUIT
stopwaitsecs=2
stopasgroup=false
killasgroup=false
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
startretries=100
OEF
}


s_exporter_haproxy(){
	${exec_prefix} echo "Exec funct echo ${FUNCNAME[0]}"
	${exec_prefix} cat << OEF > /etc/supervisor/conf.d/${FUNCNAME[0]}.conf

[supervisord]
nodaemon=true
logfile=/dev/null


[program:${FUNCNAME[0]}]
command=/etc/prometheus/exporters/haproxy_exporter --web.listen-address=":19101" --haproxy.scrape-uri=unix:/usr/share/haproxy/hapee-lb.sock
exitcodes=0,2
stopsignal=SIGTERM
stopwaitsecs=5
stopasgroup=false
killasgroup=false
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
startretries=100
OEF
}

d_harpoxy(){
	/usr/local/sbin/haproxy  -f /etc/haproxy/haproxy.conf  -p /usr/share/haproxy/haproxy.pid & export pid_run=$(/usr/share/haproxy/haproxy.pid ) &&  echo "Haproxy started. Pid ${pid_run}"
}


supervisord_run(){
	${exec_prefix} /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}
main(){
	prepare
	s_consul_agent
	#d_harpoxy
	s_consul_template
	s_exporter_haproxy
	s_harpoxy
	supervisord_run
}

main


#kill -s TERM $(ps aux | grep 'haproxy.conf' | grep -ve 'color' | grep Ssl | awk '{ print $2}')