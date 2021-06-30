#!/bin/sh

echo "$RUN_USER"
ANSIBLE_USER="$RUN_USER"
ARG_1="${1}"

ansible_init(){

# Optional deploy key
if [ ! -z "$DEPLOY_KEY" ]; then
    echo "deploy private key"
    mkdir -p /home/${ANSIBLE_USER:-ansible}/.ssh/
    ln -s ${DEPLOY_KEY} /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
    chmod 0600 /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

# Loadkey into ssh-agent if key exist
if [ -f "/home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa" ]; then
    echo "Loading ssh key to agent"
    eval $(ssh-agent)
    ssh-add /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

if [ -f "/home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa" ];then
    chmod 0600 /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

/bin/cat <<OEF> ${ANSIBLE_FILE_CONFIG:-/etc/ansible/ansible.cfg}

[defaults]
deprecation_warnings = False
private_key_file = /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
remote_tmp = /tmp/ansible-$USER
inventory = ${ANSIBLE_FILE_HOSTS:-/etc/ansible/hosts}
log_path = /tmp/.ansible.log
forks = 50
ask_pass = False
sudo_flags = -H -S
remote_port = 22
gathering = implicit
gather_timeout = 20
command_warnings = False
roles_path = ~/.ansible/roles:/usr/share/ansible/roles:/etc/ansible/roles
host_key_checking = False
remote_user = ${ANSIBLE_CONFIG_REMOTE_USER:-root}

[inventory]
enable_plugins = host_list, script, yaml

[ssh_connection]
retries=3
pipelining=${ANSIBLE_CONFIG_PIPLINING:-True}
ssh_args = -C -o ControlMaster=auto -o ControlPersist=60s

OEF

cat ${ANSIBLE_FILE_CONFIG:-/etc/ansible/ansible.cfg}

# install pip requirements, if any
if [ -z "$PIP_REQUIREMENTS" ]; then
    PIP_REQUIREMENTS=requirements.txt
fi

if [ ! -d "${LOGS_STORE_DIR:-/logs}" ]; then
    mkdir -p "${LOGS_STORE_DIR:-/logs}"
    if [ -d "${LOGS_STORE_DIR:-/logs}" ];then
        chmod 777 -v -R ${LOGS_STORE_DIR:-/logs}
    fi
fi


if [ ! -d "$ANSIBLE_ROLES_PATH" ]; then
    mkdir -p ${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}
fi

if [ ! -d "$ANSIBLE_PLAYBOOKS_PATH" ]; then
    mkdir -p ${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks}
fi

# install Galaxy roles, if any
if [ -z "$ANSIBLE_REQUIREMENTS" ]; then
    ANSIBLE_REQUIREMENTS=requirements.yml
fi



if [ -z "$ANSIBLE_REQUIREMENTS" ]; then
    ansible-galaxy install $ANSIBLE_GALAXY_PARAM -r $ANSIBLE_REQUIREMENTS
fi

if [ "${ANSIBLE_VSC}" = "False" ] ;then

    echo "ANSIBLE_VSC is false"
    echo "Skip clonning roles and playbooks"
else
    echo "Cloning files(roles and playbooks) from git repos"
    if [ -z "$ANSIBLE_GIT_PLAYBOOKS" ]; then
        echo "ANSIBLE_GIT_PLAYBOOKS is empty. Skip clonning"
    else
        if [ -f "${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks}/.git/config" ];then
            echo "Update ${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks} dir from git repo ${ANSIBLE_GIT_PLAYBOOKS}"
            cd ${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks} && GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git pull 
            else
            echo "Exec command GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git clone ${ANSIBLE_GIT_PLAYBOOKS} ${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks}"
            GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git clone ${ANSIBLE_GIT_PLAYBOOKS} ${ANSIBLE_PLAYBOOKS_PATH:-/etc/ansible/playbooks}
        fi
    fi
    
    if [ -z "$ANSIBLE_GIT_ROLES" ]; then
        echo "ANSIBLE_GIT_ROLES is empty. Skip clonning"
    else
        cd ${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}
        for ANSIBLE_GIT_ROLE in ${ANSIBLE_GIT_ROLES}
        do
        echo "Exec command GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git clone ${ANSIBLE_GIT_ROLE}"
        ANSIBLE_ROLE=$(echo "${ANSIBLE_GIT_ROLE}" | awk -F / '{print $NF}' | sed 's/\.[^.]*$//')
        if [ -f "${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}/${ANSIBLE_ROLE}/.git/config" ];then
            echo "Update role ${ANSIBLE_GIT_ROLE} in directory ${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}/${ANSIBLE_ROLE}"
            cd "${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}"/"${ANSIBLE_ROLE}" && GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git pull
        else
            echo "Clone role ${ANSIBLE_GIT_ROLE} in directory ${ANSIBLE_ROLES_PATH:-/etc/ansible/roles}/${ANSIBLE_ROLE}"
            GIT_SSH_COMMAND='ssh -i /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa' git clone ${ANSIBLE_GIT_ROLE}
        fi
        done
    fi
fi

echo "chown -R  -v ${ANSIBLE_USER:-ansible}:${ANSIBLE_USER:-ansible}  ${ANSIBLE_DIR:-/etc/ansible}"
chown -R  -v ${ANSIBLE_USER:-ansible}:${ANSIBLE_USER:-ansible}  ${ANSIBLE_DIR:-/etc/ansible}
chown -R  -v ${ANSIBLE_USER:-ansible}:${ANSIBLE_USER:-ansible}  /home/${ANSIBLE_USER:-ansible}

}

ansible_init_hosts(){
	if [[ ! -d "/etc/ansible" ]];then
		mkdir -p /etc/ansible
	fi

	echo "Init ansible hosts"
	if [ "${AWX_HOSTS_IMPORT}" = "True" ]; then
    	echo "Try import hosts from awx database ${AWX_DB_NAME}"
    	python3 /usr/local/bin/awx_hosts_export_enabled.py || (echo "Can't import hosts from awx database ${AWX_DB_NAME}")
    	echo "Import hosts from awx database ${AWX_DB_NAME} finished"
	else
    	echo "Skip import hosts from awx database ${AWX_DB_NAME}. AWX_HOSTS_IMPORT = ${AWX_HOSTS_IMPORT}"
	fi

	if [[ -f "/etc/ansible/hosts" ]];then
		echo "file /etc/ansible/hosts created"
	else
		echo "Error import hosts to file /etc/ansible/hosts"
	fi

}
supervisor_ansible_task_init(){

if [ ! -f "/etc/supervisor.d/" ];then
    mkdir -p  /etc/supervisor.d/
fi

cat <<OEF> /etc/supervisor.d/ansible_task.ini
[supervisord]
nodaemon=true

[program:ansible_task]
directory=/etc/ansible_task
command=python3 ansible_task.py
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

if [ "${ARG_1}" = "ansible_init" ];then
    ansible_init
fi

if [ "${ROLE}" == "consumer" ];then
		ansible_init
		ansible_init_hosts
    if [[ "${ENV_DEBUG}" == "True" ]];then
    	echo "Run mode - debug"
    	python3 /etc/ansible_task/ansible_task.py 2>&1
    else
    	echo "Run mode - production"
    	supervisor_ansible_task_init
    	supervisor_start
  	fi
else
    supervisor_start
fi

}


main