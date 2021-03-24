#!/usr/bin/env bash



nginx_config_dir="/etc/nginx"

configs_create(){
 
 if [[ ! -f "${nginx_config_dir}/exporters-access.conf" ]];then
 	touch ${nginx_config_dir}/exporters-access.conf
 else
 	echo "" > ${nginx_config_dir}/exporters-access.conf
 fi


 for IPS in $(echo "${EXPORTERS_SCRAPE_ALLOW_NET}"  | sed "s/,/ /g" )
 do
 	echo "${IPS}"
 	printf "allow ${IPS};\n" >> ${nginx_config_dir}/exporters-access.conf
 done

printf "deny all;\n" >> ${nginx_config_dir}/exporters-access.conf
}

nginx_run(){
	exec $(which nginx) -c ${nginx_config_dir}/nginx.conf -g "daemon off;" ${EXTRA_ARGS}
}


main(){
	configs_create
	nginx_run
}

main