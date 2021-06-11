#!/bin/bash

service_reload_haproxy(){
	code_check_config_haproxy=$(/usr/local/sbin/haproxy -c -V -f /etc/haproxy/haproxy.conf > /dev/null ; echo "return_code=$?" | awk -F= '{print $NF}')
	if [[ "${code_check_config_haproxy}" == "0" ]];then
		echo "Reload haproxy with sigkill"
	    pids_haproxy=$(ps aux | grep '/etc/haproxy/haproxy.conf' | grep -ve 'grep\|consul\|template' | grep 'Sl' | awk '{print $2}')
	    #supervisorctl restart haproxy
	    for pid_haproxy in ${pids_haproxy};do
	    	echo "exec kill -s SIGUSR1 ${pid_haproxy}"
	        kill -s SIGUSR1 ${pid_haproxy}
done
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