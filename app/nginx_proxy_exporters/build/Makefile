all: docker_build docker_tag docker_push 

DOCKER_IMAGE := $(shell grep -r 'image' docker-compose.yml | awk -F\image: '{print $$2}' | sed 's~[^-:._[:alnum:]/]\+~~g')
DOCKER_IMAGE_LATEST := $(shell grep -r 'image' docker-compose.yml | awk -F\image: '{print $$2}' | cut -d\: -f1 | sed 's~[^-:._[:alnum:]/]\+~~g' | awk '{print $$0":latest"}')


docker_build:$(eval SHELL:=/bin/bash)
		docker-compose build

docker_push:$(eval SHELL:=/bin/bash)
		docker-compose push
		#docker push "$(DOCKER_IMAGE)"
		docker push "$(DOCKER_IMAGE_LATEST)"

docker_tag:$(eval SHELL:=/bin/bash)
		docker image tag "$(DOCKER_IMAGE)" "$(DOCKER_IMAGE_LATEST)"
		
