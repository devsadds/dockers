#!/bin/bash

supervisor_start(){
	/usr/bin/supervisord -c /etc/supervisord.conf
}

main(){
	if [[ "${ENV_WORKER_FUNCTION}" == "worker" ]];then
		supervisor_start
	else
		supervisor_start
	fi
}

main


