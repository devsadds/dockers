#!/bin/sh
set -e


consul_haproxy_pxc (){

ipaddr=$(ip r | grep eth1 | awk '{print $NF}')
hostname=$(hostname)

#echo "{ \"services\": [ { \"name\": \"haproxy\", \"address\": \"$ipaddr\", \"port\": 3306, \"checks\": [ { \"name\": \"check if haproxy port is open\", \"tcp\": \"$ipaddr:3306\", \"interval\": \"35s\", \"timeout\": \"5s\" } ] } ] }" > /tmp/harpxy.json
echo "{ \"services\": [ { \"name\": \"${DOCKER_ROLE}\", \"address\": \"$ipaddr\", \"port\": 3306 } ] }" > /tmp/harpxy.json
sleep 1;
echo "show /tmp/harpxy.json"
echo "------------------------------------"
cat /tmp/harpxy.json
echo "------------------------------------"
# Starting consul client
echo "------------------------------------"
echo "exec /bin/consul agent -retry-join $DISCOVERY_SERVICE_URL -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-format json -config-file /tmp/harpxy.json &"
echo "------------------------------------"






/bin/consul agent -retry-join $DISCOVERY_SERVICE_URL -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-file /tmp/harpxy.json &
# wait to start the consul client
sleep 15
}

consul_template_pxc(){
	/usr/local/bin/consul-template -config=/opt/consul-template/config/consul-template.cfg > /var/log/consul-template/consul-template.log 2>&1 &
}

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- haproxy "$@"
fi

if [ "$1" = 'haproxy' ]; then
	shift # "haproxy"
	# if the user wants "haproxy", let's add a couple useful flags
	#   -W  -- "master-worker mode" (similar to the old "haproxy-systemd-wrapper"; allows for reload via "SIGUSR2")
	#   -db -- disables background mode
	set -- haproxy -W -db "$@"
fi

if [[ "${DOCKER_ROLE}" == "haproxy" ]];then

	if [[ "${DISCOVERY_SERVICE_URL}" == "consul" ]];then
		consul_haproxy_pxc
		consul_template_pxc
	fi
fi

exec "$@"
/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.cfg -n 4096 -N 4096


########

#######
/bin/consul agent -retry-join $DISCOVERY_SERVICE_URL -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-file /tmp/pxc.json &


function join {
  local IFS="$1"
  shift
  joined=$(tr "$IFS" '\n' <<< "$*" | sort -u | tr '\n' "$IFS")
  echo "${joined%?}"
}

set +e

# Get ips from pxc services
i1=$(dig +short -p 8600 $DISCOVERY_SERVICE_URL) || ""

# Remove this container ip from the list
i2=$(echo $i1 | sed -r "s/$ipaddr//") || ""


cluster_join=$(join , $i2 )

echo "Joining cluster $cluster_join"

set -e

/bin/consul agent -retry-join $DISCOVERY_SERVICE_URL -client 0.0.0.0 -bind $ipaddr -node $SERVER_NAME-$hostname -data-dir /tmp -config-file /tmp/pxc.json &

dig @127.0.0.1 -p 8600 $DISCOVERY_SERVICE_URL


 dig +short $DISCOVERY_SERVICE_URL
dig @127.0.0.1 -p 8600 SRV $DISCOVERY_SERVICE_URL
servicename

curl http://$DISCOVERY_SERVICE_URL:8500/v1/catalog/services?pretty

curl http://$DISCOVERY_SERVICE_URL4:8500/v1/catalog/service/pxc?pretty

dig @$DISCOVERY_SERVICE_URL-p 8600 $DISCOVERY_SERVICE_URL SR




/usr/local/sbin/haproxy -f /etc/haproxy/haproxy.conf -D 
 time haproxy -f /etc/haproxy/haproxy.conf -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)


#!/bin/bash
php_fpm_reload() {
	/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf  && /bin/kill -USR2 $(cat /var/run/haproxy.pid)

    echo "HAPROXY RELOADED"




Supervisord

echo "Run from user $(whoami).exec_prefix is ${exec_prefix}"


${exec_prefix} cat << OEF > /etc/supervisor/conf.d/haproxy.conf

[supervisord]
nodaemon=true
logfile=/dev/null


[program:haproxy]
command=/usr/local/sbin/haproxy  -f /etc/haproxy/haproxy.conf  -p /var/run/haproxy.pid
exitcodes=0,2
stopsignal=SIGTERM
stopwaitsecs=10
stopasgroup=false
killasgroup=false
autostart=true
autorestart=true
redirect_stderr=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile_maxbytes = 0
OEF


supervisorctl signal SIGHUP $(supervisorctl status | awk '{print $1}' | grep "haproxy")

${exec_prefix} /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
