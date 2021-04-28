deploy: apply_nc apply_config apply_service apply_deployment k_info_full

remove: delete_deployment delete_service delete_config

apply_nc:$(eval SHELL:=/bin/bash)
		if [ -f 01-nc.yaml ];then kubectl apply -f 01-nc.yaml;fi

apply_config:$(eval SHELL:=/bin/bash)
		if [ -f 02-config.yaml ];then kubectl apply -f 02-config.yaml;fi

apply_service:$(eval SHELL:=/bin/bash)
		if [ -f 03-service.yaml ];then kubectl apply -f 03-service.yaml;fi

apply_deployment:$(eval SHELL:=/bin/bash)
		if [ -f 04-deployment.yaml ];then kubectl apply -f 04-deployment.yaml;fi


delete_nc:$(eval SHELL:=/bin/bash)
		if [ -f 01-nc.yaml ];then kubectl delete -f 01-nc.yaml;fi

delete_config:$(eval SHELL:=/bin/bash)
		if [ -f 02-config.yaml ];then kubectl delete -f 02-config.yaml;fi

delete_service:$(eval SHELL:=/bin/bash)
		if [ -f 03-service.yaml ];then kubectl delete -f 03-service.yaml;fi

delete_deployment:$(eval SHELL:=/bin/bash)
		if [ -f 04-deployment.yaml ];then kubectl delete -f 04-deployment.yaml;fi

k_get_pods:$(eval SHELL:=/bin/bash)
		kubectl get pods -n prod-01 -o wide

k_pods_desc:$(eval SHELL:=/bin/bash)
		kubectl describe pods -n prod-01

k_labels_show:$(eval SHELL:=/bin/bash)
		kubectl get nodes --show-labels

k_info_full:$(eval SHELL:=/bin/bash)
		kubectl describe deployments.apps  -n prod-01
		kubectl get pods -n prod-01  -o wide
		kubectl describe services -n prod-01 svc-flask