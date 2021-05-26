all: docker_build docker_push

docker_build:$(eval SHELL:=/bin/bash)
		docker-compose -f docker-compose.yml build
		docker-compose -f docker-compose-http1.yml build

docker_push:$(eval SHELL:=/bin/bash)
		docker-compose -f docker-compose.yml push
		docker-compose -f docker-compose-http1.yml push




