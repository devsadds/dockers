#!/bin/bash

service_reload_haproxy(){
	code_check_config_haproxy=$(/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf > /dev/null ; echo "return_code=$?" | awk -F= '{print $NF}')
	if [[ "${code_check_config_haproxy}" == "0" ]];then
		echo "Reload haproxy with supervisord"
	    pids_haproxy=$(ps aux | grep '/etc/haproxy/haproxy.conf' | grep -ve 'grep\|consul\|template' | grep 'Sl' | awk '{print $2}')
	    sup_haproxy_status=$(supervisorctl -c /etc/supervisor/supervisord.conf status haproxy | awk '{ print $2}' )
	    if [[ "${sup_haproxy_status}" == "RUNNING" ]];then
	    	kill -s TERM $(ps aux | grep 'haproxy.conf' | grep -ve 'color' | grep Ssl | awk '{ print $2}')
	        supervisorctl -c /etc/supervisor/supervisord.conf restart haproxy
	    else
	    	echo "sup_haproxy_status=$sup_haproxy_status. Skip supervisorctl -c /etc/supervisor/supervisord.conf restart haproxy"
	    	sleep 1;
	    fi
	else
		echo "Error during code_check_config_haproxy. $(/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf). Status_Code = ${code_check_config_haproxy}"
	fi

}


main(){
	if [[ "${DOCKER_ROLE:-hapxoxy}" ]];then
		service_reload_haproxy
	fi
}
main