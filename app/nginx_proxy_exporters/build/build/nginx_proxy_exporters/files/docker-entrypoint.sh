#!/usr/bin/env bash



nginx_config_dir="/etc/nginx"

exporter_node_url_default="172.45.0.11:9100"
exporter_cadvisor_url_default="172.45.0.12:8080"
exporter_heplify_server_url_default="heplify-server:9096"

configs_create_nginx(){
 
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

if [[ ! -d "/etc/nginx/services.d/" ]];then
	mkdir -p /etc/nginx/services.d/
fi

rm -rf /etc/nginx/services.d/* || echo "Empty dir /etc/nginx/services.d"

}

config_exporter_node(){

	if [[ ! -f "/etc/nginx/services.d/exporter_node.conf" ]];then

cat <<OEF> /etc/nginx/services.d/exporter_node.conf
  server {
  listen 9100;
  
  location / {
  	include exporters-access.conf;
    proxy_pass   http://${EXPORTER_NODE_URL:-$exporter_node_url_default}/;
  }

}
OEF

fi
}


config_exporter_cadvisor(){

	if [[ ! -f "/etc/nginx/services.d/exporter_cadvisor.conf" ]];then

cat <<OEF> /etc/nginx/services.d/exporter_cadvisor.conf
  server {
  listen 9325;
  
  location / {
  	include exporters-access.conf;
    proxy_pass   http://${EXPORTER_CADVISOR_URL:-$exporter_cadvisor_url_default}/;
  }

}
OEF

fi
}



config_exporter_heplify_server(){

	if [[ ! -f "/etc/nginx/services.d/exporter_heplify_server.conf" ]];then

exporter_check_code=$(curl -s -o /dev/null -w "%{http_code}" "${EXPORTER_HEPLIFY_SERVER_URL:-$exporter_heplify_server_url_default}")

if [[ "${exporter_check_code}" != "000" ]];then

cat <<OEF> /etc/nginx/services.d/exporter_heplify_server.conf
server {
  listen 9096;
  
  location / {
  	include exporters-access.conf;
    proxy_pass   http://${EXPORTER_HEPLIFY_SERVER_URL:-$exporter_heplify_server_url_default}/;
  }

}

OEF
else
	echo "Export url ${EXPORTER_HEPLIFY_SERVER_URL:-$exporter_heplify_server_url_default} not alloweded.Skip config create."
fi
	
fi
}


nginx_run(){
	exec $(which nginx) -c ${nginx_config_dir}/nginx.conf -g "daemon off;" ${EXTRA_ARGS}
}


main(){
	configs_create_nginx
	config_exporter_node
	config_exporter_cadvisor
	config_exporter_heplify_server
	nginx_run
}

main