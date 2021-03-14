#!/bin/bash
ENV_FILE=".env"



function deploy_to_swarm() {
	export $(cat ${ENV_FILE}) && docker stack deploy -c docker-compose.yml ${DOCKER_SWARM_STACK_NAME} --with-registry-auth --orchestrator swarm --prune --resolve-image always
}

deploy_to_swarm
