#!/bin/sh

echo "$RUN_USER"

supervisor_whlisten_app_init(){

if [ ! -f "/etc/supervisor/conf.d/" ];then
    mkdir -p  /etc/supervisor/conf.d/
fi

cat <<OEF> /etc/supervisor/conf.d/whlisten.conf
[supervisord]
nodaemon=true

[program:whlisten_app]
directory=/app/whlisten
command=gunicorn whlisten:app --bind 0.0.0.0:8000  --name whlisten:app --workers=2 --threads=4 --worker-class=gthread --capture-output --log-level=info
stdout_logfile=/dev/stderr
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
autostart=true
autorestart=true
startretries=0
user=root

OEF


}

supervisor_start(){
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
}

main() {
    supervisor_whlisten_app_init
    supervisor_start
}


main