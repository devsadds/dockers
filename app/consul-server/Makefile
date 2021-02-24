all: verbose pull


DOCKER_STACK_NAME := $(shell grep -r 'DOCKER_STACK_NAME' .env | cut -d\= -f2)
DOCKER_STACK_VARS := $(shell cat .env)

verbose:$(eval SHELL:=/bin/bash)
		@echo "Stack $(DOCKER_STACK_NAME)"

prepare:$(eval SHELL:=/bin/bash)
		docker-compose pull

deploy:$(eval SHELL:=/bin/bash)
		export $(DOCKER_STACK_VARS);docker stack deploy -c docker-compose.yml $(DOCKER_STACK_NAME)

remove:$(eval SHELL:=/bin/bash)
		docker stack rm $(DOCKER_STACK_NAME)

pull:$(eval SHELL:=/bin/bash)
		@echo "Pulling up... for stack name $(DOCKER_STACK_NAME)"
		docker-compose pull



