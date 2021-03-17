#!/bin/sh

echo "$RUN_USER"

supervisor_telegram_bot_init(){

if [ ! -f "/etc/supervisor.d/" ];then
    mkdir -p  /etc/supervisor.d/
fi

cat <<OEF> /etc/supervisor.d/telegram_bot.ini
[supervisord]
nodaemon=true

[program:telegram_bot]
directory=/etc/telegram_bot
command=python3 /etc/telegram_bot/telegram_bot.py
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
startretries=4

OEF


}

supervisor_start(){
    /usr/bin/supervisord -c /etc/supervisord.conf
}

main() {

if [ "${ROLE}" == "telegram_bot" ];then
    supervisor_telegram_bot_init
    if [[ "${ENV_DEBUG}" == "True" ]];then
    	echo "Run mode - debug"
    	python3 /etc/telegram_bot/telegram_bot.py 2>&1
    else
    	echo "Run mode - production"
    	supervisor_start
  	fi
else
    supervisor_start
fi

}


main