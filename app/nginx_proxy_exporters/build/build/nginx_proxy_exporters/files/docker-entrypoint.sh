#!/usr/bin/env bash



nginx_config_dir="/etc/nginx"

exporter_node_url_default="172.30.0.11:9100"
exporter_cadvisor_url_default="172.30.0.12:8080"
exporter_mysql_url_default="172.30.0.13:9104"
exporter_postgresql_url_default="172.30.0.14:9187"
exporter_pgbouncer_url_default="172.30.0.15:9127"
exporter_elasticsearch_url_default="172.30.0.16:9114"
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


config_exporter_mysql(){

if [[ ! -f "/etc/nginx/services.d/exporter_mysql.conf" ]];then
	
	cat <<OEF> /etc/nginx/services.d/exporter_mysql.conf
	server {
	listen 9104;
	
	location / {
		include exporters-access.conf;
		proxy_pass   http://${EXPORTER_MYSQL_URL:-$exporter_mysql_url_default}/;
	}

}
OEF

fi
}

config_exporter_postgresql(){

if [[ ! -f "/etc/nginx/services.d/exporter_postgresql.conf" ]];then
	
	cat <<OEF> /etc/nginx/services.d/exporter_postgresql.conf
	server {
	listen 9187;
	
	location / {
		include exporters-access.conf;
		proxy_pass   http://${EXPORTER_POSTGRESQL_URL:-$exporter_postgresql_url_default}/;
	}

}
OEF

fi
}

config_exporter_pgbouncer(){

if [[ ! -f "/etc/nginx/services.d/exporter_pgbouncer.conf" ]];then
	
	cat <<OEF> /etc/nginx/services.d/exporter_pgbouncer.conf
	server {
	listen 9127;
	
	location / {
		include exporters-access.conf;
		proxy_pass   http://${EXPORTER_pgbouncer_URL:-$exporter_pgbouncer_url_default}/;
	}

}
OEF

fi
}

config_exporter_elasticsearch(){

if [[ ! -f "/etc/nginx/services.d/exporter_elasticsearch.conf" ]];then
	
	cat <<OEF> /etc/nginx/services.d/exporter_elasticsearch.conf
	server {
	listen 9114;
	
	location / {
		include exporters-access.conf;
		proxy_pass   http://${EXPORTER_ELASTICSEARCH_URL:-$exporter_elasticsearch_url_default}/;
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
	config_exporter_mysql
	config_exporter_postgresql
	config_exporter_pgbouncer
	config_exporter_heplify_server
	config_exporter_elasticsearch
	nginx_run
}

main