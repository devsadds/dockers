#!/bin/bash

#set -o errexit
#set -o pipefail

DOCKER_ENTRYPOINT_RUN_ARG="$1"

###ТУТ У НАС ЦВЕТА
RED='\033[0;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color

###ТУТ У НАС ПОШЛИ КЛИЕНТСКИЕ ПЕРЕМЕННЫЕ
CLIENT_ENV_FILENAME="client.env"

ENV_NGINX_DOCKER_FUNCTION_NAME_NGINX_BACKEND="nginx-backend"
ENV_NGINX_DOCKER_FUNCTION_NAME_NGINX_PROXY="nginx-proxy"
ENV_NGINX_CONF_DIR_BACKEND="/etc/nginx/backend.d"
ENV_NGINX_CONF_DIR_BACKEND_DISABLED="/etc/nginx/backend.disabled"
ENV_NGINX_CONF_DIR_PROXY="/etc/nginx/proxy.d"
ENV_NGINX_CONF_DIR_PROXY_DISABLED="/etc/nginx/proxy.disabled"
ENV_NGINX_PHP_FPM_SOCKET_DIR="/fpm-sockets"
NGINX_MEDIA_WIKI_BACKEND="10.26.0.116:1083"
NGINX_PROXY_DEFAULT_BACKEND_ASU="http://nginx-backend:80"
NGINX_PROXY_DEFAULT_BACKEND_SITE="http://nginx-backend:80"
ENV_NGINX_PROXY_CONFIG_ASU_GLOBAL_REWRITES="asu_global_rewrites_proxy.conf"
ENV_NGINX_DIR="/etc/nginx"
DATE_TIME=$(date +%Y-%m-%d-%H_%m)
HOME_DIR="/home"
DEPLOYS=$(find  ${HOME_DIR}/ -maxdepth 2 -type d  -name release | cut -c 7- | rev | cut -c9- | rev)
ACME_DIR="/var/www/letsencrypt"


exec_prefix="sudo"


####FUNCTION SHOW_VARIABLES
SHOW_VARIABLES () {
	echo "ENV_NGINX_DOCKER_FUNCTION IS ${ENV_NGINX_DOCKER_FUNCTION}"
}

####FUNCTION NGINX_RUN
NGINX_RUN () {
    #kill -9 $(ps aux | grep nginx | awk '{print $2}')
    #kill -QUIT $( cat /var/run/nginx.pid )
	nginx -g 'daemon off;'
}

####FUNCTION RUN SUPERVISOR
NGINX_RELOAD () {
    echo "ENV_ASUJS_DEPLOY_SERVER is ${ENV_ASUJS_DEPLOY_SERVER}"
    echo "exec ${exec_prefix} nginx -t && ${exec_prefix} nginx -s reload"
	${exec_prefix} /usr/sbin/nginx -t && ${exec_prefix} /usr/sbin/nginx -s reload

}

####FUNCTION CREATE DIRS FOR WORKING OUR GENERATING
NGINX_CONFIG_DIRS_CREATE () {
   if [[  ! -d ${ENV_NGINX_CONF_DIR_PROXY} ]]
   then
       mkdir -p ${ENV_NGINX_CONF_DIR_PROXY}
   fi
      
   if [[  ! -d ${ENV_NGINX_CONF_DIR_PROXY_DISABLED} ]]
   then
       mkdir -p ${ENV_NGINX_CONF_DIR_PROXY_DISABLED}
   fi

   if [[  ! -f "${ENV_NGINX_DIR}/${ENV_NGINX_PROXY_CONFIG_ASU_GLOBAL_REWRITES}" ]]
   then
       touch  ${ENV_NGINX_DIR}/${NGINX_PROXY_CONFIG_ASU_GLOBAL_REWRITES} 
   fi

   if [[ -d "${ACME_DIR}" ]]
   then
        mkdir -p "${ACME_DIR}"
        chown --recursive www-data ${ACME_DIR}
   fi
}

####FUNCTION NGINX_PHP_SOCKET_RIGHTS
NGINX_PHP_SOCKET_RIGHTS () {
    echo "Применям права на сокеты - иначе не прочитаем"
    chmod 777 -R ${ENV_NGINX_PHP_FPM_SOCKET_DIR}
}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА ASU HTTP
NGINX_BACKEND_GENERATE_CONFIG_ASU_HTTP () {
echo "${FUNCNAME[0]}"

for NGINX_ASU_HOST_HTTP in $(echo ${ASU_HOSTS_HTTP} | tr "," "\n")
do
    ASU_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_ENABLE | cut -d\= -f2)
    if [[ ${ASU_ENABLE} == "true" ]]
    then
        if [[ "${ASU_HOSTS_HTTP}" != "" ]]
        then
        echo -e "${RED} NGINX_ASU_HOST_HTTP is ${NGINX_ASU_HOST_HTTP} ${NC}"
        echo -e "${CYAN} Генерируем nginx config ${NGINX_ASU_HOST_HTTP} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
        ASU_DIR_NAME=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_DIR_NAME_${NGINX_ASU_HOST_HTTP} | cut -d\= -f2)
        #debug
        echo " grep -q ${NGINX_ASU_HOST_HTTP} ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf && echo ${NGINX_ASU_HOST_HTTP} уже существует"
            if [[ ! -f "${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf" ]]
            then
            touch ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf
            fi
        grep -q "${NGINX_ASU_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf && echo "${NGINX_ASU_HOST_HTTP} уже существует" ||  /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf
###NGINX BACKEND CONFIG BEGIN for ${NGINX_ASU_HOST_HTTP}
server {
    listen 80;
    server_name
    ${NGINX_ASU_HOST_HTTP}
    www.${NGINX_ASU_HOST_HTTP}
    ;

    ##Data folder asu
    root /home/${DEPLOY}/${ASU_DIR_NAME:-release};
    index index.php index.html index.htm;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    ###обработка maintenance
    if (-f \$document_root/maintenance.html) {
        return 503;
    }
    error_page 503 @maintenance;
    
    location @maintenance {
        rewrite ^(.*)$ /maintenance.html break;
    }
    location ~ \.php$ {
        location ~ /wiki/.*\.php$ {
        proxy_pass http://${NGINX_MEDIA_WIKI_BACKEND};
        }
        try_files  \$uri =404;
        fastcgi_pass unix:${ENV_NGINX_PHP_FPM_SOCKET_DIR}/php-fpm-${DEPLOY}.sock;
        fastcgi_read_timeout 320;
        fastcgi_send_timeout 320;
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME   \$document_root\$fastcgi_script_name;
        fastcgi_param    PATH    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/node/bin:/bin;
        include fastcgi_params;
    }

    location ~* /api/(.*)\$ {
         try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location  /wiki/ {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://${NGINX_MEDIA_WIKI_BACKEND}/wiki/;
    }
}
###NGINX BACKEND CONFIG END for ${NGINX_ASU_HOST_HTTP}
OEF
        else
        echo -e "${RED} Variable ASU_HOSTS_HTTP is empty. Skip generating config for ASU_HOSTS_HTTP ${NC}"
        fi
    fi
        if [[ ${ASU_ENABLE} == "false" ]]
        then
                echo -e "${RED} ASU_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_ASU_HOST_HTTP} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf"
                PATTERN1="###NGINX BACKEND CONFIG BEGIN for ${NGINX_ASU_HOST_HTTP}"
                PATTERN2="###NGINX BACKEND CONFIG END for ${NGINX_ASU_HOST_HTTP}"
                grep -q "${NGINX_ASU_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_ASU_HOST_HTTP}"
        fi
done

}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА SITE HTTP
NGINX_BACKEND_GENERATE_CONFIG_SITE_HTTP () {
echo "${FUNCNAME[0]}"

for NGINX_SITE_HOST_HTTP in $(echo ${SITE_HOSTS_HTTP} | tr "," "\n")
do
    SITE_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_ENABLE | cut -d\= -f2)
    if [[ ${SITE_ENABLE} == "true" ]]
    then
        if [[ "${SITE_HOSTS_HTTP}" != "" ]]
        then
        echo -e "${CYAN} Генерируем nginx config ${NGINX_SITE_HOST_HTTP} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
        SITE_DIR_NAME=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_DIR_NAME_${NGINX_SITE_HOST_HTTP} | cut -d\= -f2)
        SITE_API_URL=$(cat ${HOME_DIR}/${DEPLOY}/${SITE_DIR_NAME:-site}/config/params.php  | grep apiUrl  | cut -d'/' -f2- | tr -d \' | tr -d \/ | tr -d \,)
        SITE_API_URL_DEFAULT=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_HOSTS_HTTP | cut -d\= -f2 | tr "," "\n" | head -n 1 )
            if [[ ! -f "${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf" ]]
            then
            touch ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf
            fi
            #проверяем не пустая липерменная SITE_API_URL
            if [[ -n "${SITE_API_URL/[ ]*\n/}" ]] || [[  ${SITE_API_URL} =~ .*apiUrl.* ]]
            then
                echo -e "${RED} Переменная SITE_API_URL пустая - подменяем ее на SITE_API_URL_DEFAULT ${NC}"
                echo ""
                SITE_API_URL=$(echo ${SITE_API_URL_DEFAULT})

            else
                echo -e "${RED} Переменная SITE_API_URL не пустая - все ок ${NC}"
                echo ""
            fi
            
        grep -q "${NGINX_SITE_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf && echo "${NGINX_SITE_HOST_HTTP} уже существует" ||  /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf

###NGINX BACKEND CONFIG BEGIN for ${NGINX_SITE_HOST_HTTP}
server {
    listen 80;
    server_name
    ${NGINX_SITE_HOST_HTTP}
    www.${NGINX_SITE_HOST_HTTP}
    ;
    ##Data folder site
    root /home/${DEPLOY}/${SITE_DIR_NAME:-site}/web;
    
    index index.php index.html index.htm;
    location / {
    # Redirect everything that isn't a real file to index.php
        try_files \$uri \$uri/ /index.php\$is_args\$args;
    }
    
    location ~ \.php$ {
        try_files  \$uri =404;
        fastcgi_pass unix:${ENV_NGINX_PHP_FPM_SOCKET_DIR}/php-fpm-${DEPLOY}.sock;
        fastcgi_read_timeout 120;
        fastcgi_send_timeout 120;
        fastcgi_index index.php;
        fastcgi_param  SCRIPT_FILENAME   \$document_root\$fastcgi_script_name;
        fastcgi_param    PATH    /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/opt/node/bin:/bin;
        include fastcgi_params;
    }
    location /reformagkh {
        rewrite ^/reformagkh/(.*)$ http://${SITE_API_URL}/uploads/reformagkh/profile988/\$1 redirect;
    }
    location /images {
        autoindex on;
    }

}
###NGINX BACKEND CONFIG END for ${NGINX_SITE_HOST_HTTP}
OEF
        else
        echo -e "${RED} Variable SITE_HOSTS_HTTP is empty. Skip generating config for SITE_HOSTS_HTTP ${NC}"
        fi
    fi
        if [[ ${SITE_ENABLE} == "false" ]]
        then
                echo -e "${RED} SITE_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_SITE_HOST_HTTP} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf"
                PATTERN1="###NGINX BACKEND CONFIG BEGIN for ${NGINX_SITE_HOST_HTTP}"
                PATTERN2="###NGINX BACKEND CONFIG END for ${NGINX_SITE_HOST_HTTP}"
                grep -q "${NGINX_SITE_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_BACKEND}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_SITE_HOST_HTTP}"
        fi
done

}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА ASU HTTP
NGINX_PROXY_GENERATE_CONFIG_ASU_HTTP () {
echo "${FUNCNAME[0]}"

for NGINX_ASU_HOST_HTTP in $(echo ${ASU_HOSTS_HTTP} | tr "," "\n")
do
ASU_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_ENABLE | cut -d\= -f2)

    if [[ ${ASU_ENABLE} == "true" ]]
    then
        if [[ "${ASU_HOSTS_HTTP}" != "" ]]
        then

            echo -e "${CYAN} Генерируем nginx config ${NGINX_ASU_HOST_HTTP} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
            NGINX_PROXY_BACKEND_ASU=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_BACKEND_SERVER_HOST | cut -d\= -f2)
            ASU_WEBSOCKET_SERVER_HOST=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_WEBSOCKET_SERVER_HOST | cut -d\= -f2)
            NGINX_PROXY_ROOT_DOMAIN=$(echo "${NGINX_ASU_HOST_HTTP}" |  cut -d'.' -f2- )
              if [[ ! -f "${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf" ]]
              then
              touch ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
              fi
            grep -q "${NGINX_ASU_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && echo "${NGINX_ASU_HOST_HTTP} уже существует" || /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
###NGINX PROXY CONFIG BEGIN for ${NGINX_ASU_HOST_HTTP}
server {
    listen 80;
    server_name
    ${NGINX_ASU_HOST_HTTP}
    www.${NGINX_ASU_HOST_HTTP}
    ;
    root /dev/null;                  
    location / {
        proxy_pass   ${NGINX_PROXY_BACKEND_ASU:-${NGINX_PROXY_DEFAULT_BACKEND_ASU}}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 120;
        proxy_send_timeout 120;
        proxy_read_timeout 180;
    }
    location  /wiki/ {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://${NGINX_MEDIA_WIKI_BACKEND}/wiki/;
        proxy_redirect default;
    }
}                   
               
###Конфиг proxy websock без ssl - без ssl всегда 8082
server {
    listen 8082;
    server_name
    ${NGINX_ASU_HOST_HTTP}
    ;
    access_log off;
    location / {
        proxy_pass ${ASU_WEBSOCKET_SERVER_HOST:-http://websock:8082};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        }            
}

###NGINX PROXY CONFIG END for ${NGINX_ASU_HOST_HTTP}
OEF
        else
        echo -e "${RED} Variable ASU_HOSTS_HTTP is empty. Skip generating config for ASU_HOSTS_HTTP ${NC}"
        fi
    fi
        if [[ ${ASU_ENABLE} == "false" ]]
        then
                echo -e "${RED} ASU_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_ASU_HOST_HTTP} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf"
                PATTERN1="###NGINX PROXY CONFIG BEGIN for ${NGINX_ASU_HOST_HTTP}"
                PATTERN2="###NGINX PROXY CONFIG END for ${NGINX_ASU_HOST_HTTP}"
                grep -q "${NGINX_ASU_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_ASU_HOST_HTTP}"
        fi
done
}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА ASU SSL
NGINX_PROXY_GENERATE_CONFIG_ASU_SSL () {
echo "${FUNCNAME[0]}"

for NGINX_ASU_HOST_SSL in $(echo ${ASU_HOSTS_SSL} | tr "," "\n")
do
ASU_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_ENABLE | cut -d\= -f2)

    if [[ ${ASU_ENABLE} == "true" ]]
    then
        if [[ "${ASU_HOSTS_SSL}" != "" ]]
        then

            echo -e "${CYAN} Генерируем nginx config ${NGINX_ASU_HOST_SSL} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
            NGINX_PROXY_BACKEND_ASU=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_BACKEND_SERVER_HOST | cut -d\= -f2)
            ASU_WEBSOCKET_SERVER_HOST=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_WEBSOCKET_SERVER_HOST | cut -d\= -f2)
            NGINX_PROXY_ROOT_DOMAIN=$(echo "${NGINX_ASU_HOST_SSL}" |  cut -d'.' -f2- )
                   ##Проверяем какой порт использовать для сокетов при шифровании
                   if [[ ${NGINX_PROXY_ROOT_DOMAIN} == "smart-uk.ru" ]]
                   then
                   NGINX_PROXY_WEBSOCKET_BACKEND_PORT="8083"
                   else
                   NGINX_PROXY_WEBSOCKET_BACKEND_PORT="8081"
                   fi
                      if [[ ! -f "${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf" ]]
                      then
                      touch ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
                      fi
                        if [[ -f "/etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf" ]]
                        then
                        grep -q "${NGINX_ASU_HOST_SSL}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && echo "${NGINX_ASU_HOST_SSL} уже существует" || /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
###NGINX PROXY CONFIG BEGIN for ${NGINX_ASU_HOST_SSL}
server {
    listen 80;
    server_name
    ${NGINX_ASU_HOST_SSL}
    www.${NGINX_ASU_HOST_SSL}
    ;
    return 301 https://${NGINX_ASU_HOST_SSL}\$request_uri;
}          
server {
    listen 443 ssl http2;
    server_name 
    ${NGINX_ASU_HOST_SSL}
    ;
    #Include ssl config
    include /etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf;
    client_max_body_size 400m;                   
    location / {
        proxy_pass   ${NGINX_PROXY_BACKEND_ASU:-${NGINX_PROXY_DEFAULT_BACKEND_ASU}}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 120;
        proxy_send_timeout 120;
        proxy_read_timeout 180;
    }
    location  /wiki/ {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_pass http://${NGINX_MEDIA_WIKI_BACKEND}/wiki/;
        proxy_redirect default;
    }
    include ${ENV_NGINX_PROXY_CONFIG_ASU_GLOBAL_REWRITES};
}                   
###WEBSOCK PROXY CONFIG FOR ZONE ${NGINX_PROXY_ROOT_DOMAIN}
server {
    listen ${NGINX_PROXY_WEBSOCKET_BACKEND_PORT} http2 ssl;
    server_name
    ${NGINX_ASU_HOST_SSL}
    ;
    #Include ssl config
    include /etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf;
    access_log off;
    location / {
        proxy_pass ${ASU_WEBSOCKET_SERVER_HOST:-http://websock:8082};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}   
                   
###Конфиг proxy websock без ssl - без ssl всегда 8082
server {
    listen 8082;
    server_name
    ${NGINX_ASU_HOST_SSL}
    ;
    access_log off;
    location / {
        proxy_pass ${ASU_WEBSOCKET_SERVER_HOST:-http://websock:8082};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$host;
        proxy_set_header X-NginX-Proxy true;
        proxy_set_header X-Forwarded-Proto \$scheme;
        }            
}
###NGINX PROXY CONFIG END for ${NGINX_ASU_HOST_SSL}
OEF
                    else
                    echo -e "${RED} Файла с конфигурацией SSL \"/etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf\" не существует. Ничего не генерируем ${NC}"
                    fi
        else
        echo -e "${RED} Variable ASU_HOSTS_SSL is empty. Skip generating config for ASU_HOSTS_SSL ${NC}"
        fi
    fi

if [[ ${ASU_ENABLE} == "false" ]]
then
        echo -e "${RED} ASU_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_ASU_HOST_SSL} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf"
        PATTERN1="###NGINX PROXY CONFIG BEGIN for ${NGINX_ASU_HOST_SSL}"
        PATTERN2="###NGINX PROXY CONFIG END for ${NGINX_ASU_HOST_SSL}"
        grep -q "${NGINX_ASU_HOST_SSL}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_ASU_HOST_SSL}"
fi

done
}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА SITE SSL
NGINX_PROXY_GENERATE_CONFIG_SITE_SSL () {
echo "${FUNCNAME[0]}"

for NGINX_SITE_HOST_SSL in $(echo ${SITE_HOSTS_SSL} | tr "," "\n")
do
SITE_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_ENABLE | cut -d\= -f2)

    if [[ ${SITE_ENABLE} == "true" ]]
    then
        if [[ "${SITE_HOSTS_SSL}" != "" ]]
        then

            echo -e "${CYAN} Генерируем nginx config ${NGINX_SITE_HOST_SSL} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
            NGINX_PROXY_BACKEND_ASU=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_BACKEND_SERVER_HOST | cut -d\= -f2)
            ASU_WEBSOCKET_SERVER_HOST=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_WEBSOCKET_SERVER_HOST | cut -d\= -f2)
            NGINX_PROXY_ROOT_DOMAIN=$(echo "${NGINX_SITE_HOST_SSL}" |  cut -d'.' -f2- )
                if [[ -f "/etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf" ]]
                then
                      if [[ ! -f "${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf" ]]
                      then
                      touch ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
                      fi
                grep -q "${NGINX_SITE_HOST_SSL}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && echo "${NGINX_SITE_HOST_SSL} уже существует" || /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
###NGINX PROXY CONFIG BEGIN for ${NGINX_SITE_HOST_SSL}
server {
    listen 80;
    server_name
    ${NGINX_SITE_HOST_SSL}
    www.${NGINX_SITE_HOST_SSL}
    ;
    return 301 https://${NGINX_SITE_HOST_SSL}\$request_uri;
}



###Конфиг сайта
server {
  listen 443 ssl http2;
    server_name
    ${NGINX_SITE_HOST_SSL}
    ;
     #Include ssl config
    include /etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf;

    ##Data folder site
    root /dev/null;
    
    index index.php index.html index.htm;
    location / {
        proxy_pass   ${NGINX_PROXY_BACKEND_SITE:-${NGINX_PROXY_DEFAULT_BACKEND_SITE}}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 120;
        proxy_send_timeout 120;
        proxy_read_timeout 120;
}

}
###NGINX PROXY CONFIG END for ${NGINX_SITE_HOST_SSL}
OEF
                    else
                    echo -e "${RED} Файла с конфигурацией SSL \"/etc/nginx/ssl.d/${NGINX_PROXY_ROOT_DOMAIN}/ssl.${NGINX_PROXY_ROOT_DOMAIN}.conf\" не существует. Ничего не генерируем ${NC}"
                    fi
        else
        echo -e "${RED} Variable SITE_HOSTS_SSL is empty. Skip generating config for SITE_HOSTS_SSL ${NC}"
        fi
    fi

if [[ ${SITE_ENABLE} == "false" ]]
then
        PATTERN1="###NGINX PROXY CONFIG BEGIN for ${NGINX_SITE_HOST_SSL}"
        PATTERN2="###NGINX PROXY CONFIG END for ${NGINX_SITE_HOST_SSL}"
        echo -e "${RED} SITE_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_SITE_HOST_SSL} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf"
        grep -q "${NGINX_SITE_HOST_SSL}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_SITE_HOST_SSL}"
fi

done
}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГА SITE HTTP
NGINX_PROXY_GENERATE_CONFIG_SITE_HTTP () {
echo "${FUNCNAME[0]}"

for NGINX_SITE_HOST_HTTP in $(echo ${SITE_HOSTS_HTTP} | tr "," "\n")
do
SITE_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_ENABLE | cut -d\= -f2)

    if [[ ${SITE_ENABLE} == "true" ]]
    then
        if [[ "${SITE_HOSTS_HTTP}" != "" ]]
        then

            echo -e "${CYAN} Генерируем nginx config ${NGINX_SITE_HOST_HTTP} для ${ENV_NGINX_DOCKER_FUNCTION} ${NC}"
            NGINX_PROXY_BACKEND_SITE=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_BACKEND_SERVER_HOST | cut -d\= -f2)
            SITE_WEBSOCKET_SERVER_HOST=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_WEBSOCKET_SERVER_HOST | cut -d\= -f2)
            NGINX_PROXY_ROOT_DOMAIN=$(echo "${NGINX_SITE_HOST_HTTP}" |  cut -d'.' -f2- )
               if [[ ! -f "${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf" ]]
               then
               touch ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
               fi
            grep -q "${NGINX_SITE_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && echo "${NGINX_SITE_HOST_HTTP} уже существует" || /bin/cat <<OEF>> ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf
###NGINX PROXY CONFIG BEGIN for ${NGINX_SITE_HOST_HTTP}
server {
    listen 80;
    server_name
    ${NGINX_SITE_HOST_HTTP}
    www.${NGINX_SITE_HOST_HTTP}
    ;

    ##Data folder site
    root /dev/null;
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt/;
    }

    location / {
        proxy_pass   ${NGINX_PROXY_BACKEND_SITE:-${NGINX_PROXY_DEFAULT_BACKEND_SITE}}/;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 120;
        proxy_send_timeout 120;
        proxy_read_timeout 120;
    }
}
###NGINX PROXY CONFIG END for ${NGINX_SITE_HOST_HTTP}
OEF
        else
        echo -e "${RED} Variable SITE_HOSTS_HTTP is empty. Skip generating config for SITE_HOSTS_HTTP ${NC}"
        fi
    fi
        if [[ ${SITE_ENABLE} == "false" ]]
        then
                echo -e "${RED} SITE_ENABLE is  \"false\" ${NC}. Удаляем из конфига секцию с ${NGINX_SITE_HOST_HTTP} ${PATTERN1} ${PATTERN2} из файла ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf"
                PATTERN1="###NGINX PROXY CONFIG BEGIN for ${NGINX_SITE_HOST_HTTP}"
                PATTERN2="###NGINX PROXY CONFIG END for ${NGINX_SITE_HOST_HTTP}"
                grep -q "${NGINX_SITE_HOST_HTTP}" ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf && sed -i "/${PATTERN1}/,/${PATTERN2}/d"  ${ENV_NGINX_CONF_DIR_PROXY}/${DEPLOY}.conf || echo "Конфиг был очищен ранее или не попадает под паттерн удаления ${NGINX_SITE_HOST_HTTP}"
        fi
done
}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГОВ NGINX ДЛЯ BACKEND
NGINX_GENERATE_CONFIG_BACKEND () {

echo "${FUNCNAME[0]}"
for DEPLOY in ${DEPLOYS}
do
if [[ -f "${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME}" ]]
then
ASU_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_ENABLE | cut -d\= -f2)
SITE_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_ENABLE | cut -d\= -f2)
ASU_HOSTS_HTTP=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_HOSTS_HTTP | cut -d\= -f2)
ASU_HOSTS_SSL=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_HOSTS_SSL | cut -d\= -f2)
SITE_HOSTS_HTTP=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_HOSTS_HTTP | cut -d\= -f2)
SITE_HOSTS_SSL=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_HOSTS_SSL | cut -d\= -f2)
SITE_API_URL=$(cat ${HOME_DIR}/${DEPLOY}/site/config/params.php  | grep apiUrl  | cut -d'/' -f2- | tr -d \' | tr -d \/ | tr -d \,)
SITE_API_URL_ROOT_DOMAIN=$(echo ${SITE_API_URL} | cut -d\. -f2-)

NGINX_CONFIG_DIRS_CREATE
NGINX_BACKEND_GENERATE_CONFIG_ASU_HTTP
NGINX_BACKEND_GENERATE_CONFIG_SITE_HTTP
else
echo -e "${RED} ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} not exist. SKIP GENERATING CONFIG ${NC}"
fi
done

}

##ФУНКЦИЯ ГЕНЕРАЦИЯ КОНФИГОВ NGINX ДЛЯ PROXY
NGINX_GENERATE_CONFIG_PROXY () {
echo "${FUNCNAME[0]}"

for DEPLOY in ${DEPLOYS}
do
if [[ -f "${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME}" ]]
then
ASU_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^ASU_ENABLE | cut -d\= -f2)
SITE_ENABLE=$(cat ${HOME_DIR}/${DEPLOY}/client.env | grep ^SITE_ENABLE | cut -d\= -f2)
ASU_HOSTS_HTTP=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_HOSTS_HTTP | cut -d\= -f2)
ASU_HOSTS_SSL=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^ASU_HOSTS_SSL | cut -d\= -f2)
SITE_HOSTS_HTTP=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_HOSTS_HTTP | cut -d\= -f2)
SITE_HOSTS_SSL=$(cat ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} | grep ^SITE_HOSTS_SSL | cut -d\= -f2)
SITE_API_URL=$(cat ${HOME_DIR}/${DEPLOY}/site/config/params.php  | grep apiUrl  | cut -d'/' -f2- | tr -d \' | tr -d \/ | tr -d \,)
SITE_API_URL_ROOT_DOMAIN=$(echo ${SITE_API_URL} | cut -d\. -f2-)

NGINX_CONFIG_DIRS_CREATE
NGINX_PROXY_GENERATE_CONFIG_ASU_SSL
NGINX_PROXY_GENERATE_CONFIG_ASU_HTTP
NGINX_PROXY_GENERATE_CONFIG_SITE_SSL
NGINX_PROXY_GENERATE_CONFIG_SITE_HTTP
else
echo -e "${RED} ${HOME_DIR}/${DEPLOY}/${CLIENT_ENV_FILENAME} not exist. SKIP GENERATING CONFIG ${NC}"
fi
done
}

##ФУНКЦИЯ ОПРЕДЕЛЕНИЯ - BACKEND ИЛИ PROXY. ТАК ЖЕ ОПРЕДЕЛЯЕМ КАКИМ АГРУМЕНТОМ ЗАПУСКАТЬ UPDATE КОНФИГОВ
MAIN() {
echo "${FUNCNAME[0]}"
echo "DOCKER_ENTRYPOINT_RUN_ARG IS ${DOCKER_ENTRYPOINT_RUN_ARG}"
if [[ "${DOCKER_ENTRYPOINT_RUN_ARG}" == "UPDATE" ]]
then
    echo -e "${CYAN} DOCKER_ENTRYPOINT_RUN_ARG is  ${DOCKER_ENTRYPOINT_RUN_ARG} executing UPDATE_CONFIGS ${NC} "
    if [[ "${ENV_NGINX_DOCKER_FUNCTION}" == "${ENV_NGINX_DOCKER_FUNCTION_NAME_NGINX_PROXY}" ]]
	then
        echo -e "${CYAN} VARIABLE \"DOCKER_ENTRYPOINT_RUN_ARG\" ${NC}"
		NGINX_GENERATE_CONFIG_PROXY
        NGINX_RELOAD
    elif [[ "${ENV_NGINX_DOCKER_FUNCTION}" == "${ENV_NGINX_DOCKER_FUNCTION_NAME_NGINX_BACKEND}" ]]
    then
        echo -e "${CYAN} VARIABLE \"DOCKER_ENTRYPOINT_RUN_ARG\" ${NC}"
    	NGINX_GENERATE_CONFIG_BACKEND
        NGINX_RELOAD
    else
    	echo "${CYAN} ENV_NGINX_DOCKER_FUNCTION is empty or undefined. Nothing to do ${NC}"
        #NGINX_RUN
    fi
    elif [[ "${DOCKER_ENTRYPOINT_RUN_ARG}" == "" ]]
    then
    echo -e "${CYAN} VARIABLE \"DOCKER_ENTRYPOINT_RUN_ARG\"   is not \"UPDATE\" or \"START\". SKIP ${NC}"
    else
      #statements  
    
    NGINX_RUN
fi 
    echo "Script runned from user $(whoami)" 
}

####ПРОСТО ВЫЗОВ MASTER ФУНКЦИИ
MAIN


#finish() {
  #result=$?
  ## Your cleanup code here
  #exit ${result}
#}
#trap finish EXIT ERR
