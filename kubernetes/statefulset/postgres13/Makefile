KUBE_NS := $(shell grep -r 'KUBE_NS' .env | cut -d\= -f2)

deploy: apply_nc apply_config apply_storage apply_service apply_deployment k_info_full

remove: delete_deployment delete_service delete_config

delete_all: delete_deployment delete_service delete_storage delete_config delete_nc

apply_nc:$(eval SHELL:=/bin/bash)
		kubectl apply -f 01-nc.yaml

apply_config:$(eval SHELL:=/bin/bash)
		kubectl apply -f 02-config.yaml

apply_storage:$(eval SHELL:=/bin/bash)
		kubectl apply -f 02-storage.yaml

apply_service:$(eval SHELL:=/bin/bash)
		kubectl apply -f 03-service.yaml

apply_deployment:$(eval SHELL:=/bin/bash)
		kubectl apply -f 04-deployment.yaml
		kubectl describe deployments.apps  -n $(KUBE_NS)
		kubectl get pods -n $(KUBE_NS)  -o wide

delete_nc:$(eval SHELL:=/bin/bash)
		kubectl delete -f 01-nc.yaml

delete_nc:$(eval SHELL:=/bin/bash)
		kubectl delete -f 01-nc.yaml

delete_config:$(eval SHELL:=/bin/bash)
		kubectl delete -f 02-config.yaml

delete_storage:$(eval SHELL:=/bin/bash)
		kubectl delete -f 02-storage.yaml

delete_service:$(eval SHELL:=/bin/bash)
		kubectl delete -f 03-service.yaml

delete_deployment:$(eval SHELL:=/bin/bash)
		kubectl delete -f 04-deployment.yaml

k_get_pods:$(eval SHELL:=/bin/bash)
		kubectl get pods -n $(KUBE_NS) -o wide

k_pods_desc:$(eval SHELL:=/bin/bash)
		kubectl describe pods -n $(KUBE_NS)

k_labels_show:$(eval SHELL:=/bin/bash)
		kubectl get nodes --show-labels

k_info_full:$(eval SHELL:=/bin/bash)
		kubectl describe deployments.apps  -n $(KUBE_NS)
		kubectl get pods -n $(KUBE_NS)  -o wide
