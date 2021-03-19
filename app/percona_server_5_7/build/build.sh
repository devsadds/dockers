#!/bin/bash

orig_docker=$(grep -oP 'devsadds.*' docker-compose.yml)

docker_local_push(){
	docker login localregistry.linux2be.com:1443 -u a.v.galushko  -p 04-FadeToBlack04-TurnThePage
	docker tag  ${orig_docker}  localregistry.linux2be.com:1443/${orig_docker}
	docker push localregistry.linux2be.com:1443/${orig_docker}
}


docker-compose build  && docker_local_push && docker-compose push
