#!/bin/bash

prepare(){
if [[ ! -f "/etc/ssh/ssh_host_rsa_key" ]]; then
	# generate fresh rsa key
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [[ ! -f "/etc/ssh/ssh_host_dsa_key" ]]; then
	# generate fresh dsa key
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi
	sleep 5;
if [[ ! -d "/home/borg/.ssh" ]];then
	echo "Exec mkdir -p  /home/borg/.ssh"
	mkdir -pv  /home/borg/.ssh
fi

if [[ ! -f "/home/borg/.ssh/authorized_keys" ]];then
	touch /home/borg/.ssh/authorized_keys
fi


if [[ "${BORG_SERVER_BACKUP_FOLDER}" == "" ]];then
	echo "var BORG_SERVER_BACKUP_FOLDER is empty"
else
	echo "Prepare ${BORG_SERVER_BACKUP_FOLDER}"
	if [[ ! -d "${BORG_SERVER_BACKUP_FOLDER}" ]];then
		echo "Creating ${BORG_SERVER_BACKUP_FOLDER}"
		mkdir -pv ${BORG_SERVER_BACKUP_FOLDER}
		#nohup chown -R borg:borg ${BORG_SERVER_BACKUP_FOLDER} &
		#nohup chown -R borg:borg /bup || echo "not exist"  &
	else
		echo "change user to  borg:borg for directory ${BORG_SERVER_BACKUP_FOLDER}"
		#nohup chown -R borg:borg ${BORG_SERVER_BACKUP_FOLDER} &
	fi

fi

#prepare run dir
if [[ ! -d "/var/run/sshd" ]]; then
  	mkdir -p /var/run/sshd
fi

if [[ -d /home/borg/.ssh ]];then
	chmod  700 -v /home/borg/.ssh
	chmod  700 -v /home/borg/.ssh/authorized_keys
fi
}

fix_perms(){
	if [[ -d "/home/borg" ]];then
		screen -dmSL ${FUNCNAME}_borg sh -c "find /home/borg \! -user borg -exec chown -h -v borg:borg {} +;find /home/borg \! -group borg -exec chown -h -v borg:borg {} +;"
	fi
	if [[ -d "/bup" ]];then
		screen -dmSL ${FUNCNAME}_bup sh -c "find /bup \! -user borg -exec chown -h -v borg:borg {} +;find /bup \! -group borg -exec chown -h -v borg:borg {} +;"
	fi


}


prepare
fix_perms
exec "$@"

