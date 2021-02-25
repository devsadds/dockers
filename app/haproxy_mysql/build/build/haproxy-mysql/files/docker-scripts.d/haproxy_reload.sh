#!/bin/bash

service_reload_haproxy(){
	/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf && kill -s SIGUSR1 $(ps aux | grep '/etc/haproxy/haproxy.conf' | grep -ve 'grep\|consul\|template' | awk '{print $2}')
	#/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf && /usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf  && /bin/kill -USR2 $(cat /usr/share/haproxy/haproxy.pid)
}

service_reload_haproxy_iptables(){
	iptables -I INPUT -p tcp --dport 3306 --syn -j DROP
	iptables -I INPUT -p tcp --dport 3307 --syn -j DROP
	sleep 1
	supervisorctl -u login -p pass restart haproxy:*
	iptables -D INPUT -p tcp --dport 3306 --syn -j DROP
	iptables -D INPUT -p tcp --dport 3307 --syn -j DROP
}


main(){
	if [[ "${DOCKER_ROLE:-hapxoxy}" ]];then
		service_reload_haproxy
	fi
}
main


