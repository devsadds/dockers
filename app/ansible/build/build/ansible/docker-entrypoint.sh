#!/bin/sh
ANSIBLE_USER="$RUN_USER"
echo ""
echo "${DEPLOY_KEY}" 

docker_init() {
if [ -f "ansible.log" ]; then
    DATE_LOG=$(date -d "$(head -1 ansible.log  | cut -d, -f1 )" +%Y%m%d-%H%M%S) 2>/dev/null
    if [ -n "$DATE_LOG" ]; then
        mv ansible.log ansible-${DATE_LOG}.log
        gzip ansible-${DATE_LOG}.log &
    fi
fi

# Optional deploy key
if [ ! -z "$DEPLOY_KEY" ]; then
    echo "deploy private key"
    mkdir -p /home/${ANSIBLE_USER:-ansible}/.ssh/
    ln -s ${DEPLOY_KEY} /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
    chmod 0600 /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

if [ -f "/home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa" ]; then
    echo "Loading ssh key to agent"
    eval $(ssh-agent)
    ssh-add /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

if [ -f "/home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa" ];then
    chmod 0600 /home/${ANSIBLE_USER:-ansible}/.ssh/id_rsa
fi

}


main() {
    docker_init
}

main
"$@"