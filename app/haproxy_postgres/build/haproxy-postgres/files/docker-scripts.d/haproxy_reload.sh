#!/bin/bash

service_reload_haproxy(){
	/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf && export old_pid=$(cat /usr/share/haproxy/haproxy.pid) &&  /usr/local/sbin/haproxy  -f /etc/haproxy/haproxy.conf  -p /usr/share/haproxy/haproxy.pid  && /bin/kill -s SIGUSR1 ${old_pid} && echo "reloaded haproxy (old pid  ${old_pid})."
}

main(){
	service_reload_haproxy
}
main






