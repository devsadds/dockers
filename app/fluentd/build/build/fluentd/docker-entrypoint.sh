#!/usr/bin/dumb-init /bin/sh

uid=${FLUENT_UID:-1000}

# check if a old fluent user exists and delete it
cat /etc/passwd | grep fluent
if [ $? -eq 0 ]; then
    deluser fluent
fi

# (re)add the fluent user with $FLUENT_UID
adduser -D -g '' -u ${uid} -h /home/fluent fluent

#source vars if file exists
DEFAULT=/etc/default/fluentd

if [ -r $DEFAULT ]; then
    set -o allexport
    source $DEFAULT
    set +o allexport
fi
if [ ! -d "/fluentdlogs" ];then
	mkdir -p /fluentdlogs
fi
# chown home and data folder
chown -R fluent /home/fluent
chown -R fluent /fluentd
chown -R fluent /fluentdlogs
#exec su-exec fluent "$@"

/usr/bin/supervisord -c /etc/supervisord.conf 