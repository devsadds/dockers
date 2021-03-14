#!/bin/bash
ENV_FILE=".env"


function remove_from_swarm() {
	export $(cat ${ENV_FILE}) && docker stack rm ${DOCKER_SWARM_STACK_NAME}
}

function clean_docker_system() {
	docker system prune -f && docker network prune -f 	
}
remove_from_swarm
clean_docker_system