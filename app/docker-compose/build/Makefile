all: docker_build docker_push

docker_build:$(eval SHELL:=/bin/bash)
		COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose build

docker_push:$(eval SHELL:=/bin/bash)
		COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker-compose push




