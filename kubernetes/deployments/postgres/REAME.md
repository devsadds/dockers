kubectl label nodes k8s-node-0  app=postgres --overwrite
kubectl label nodes k8s-node-0  tier=database --overwrite
kubectl label nodes k8s-node-0  environment=production  --overwrite

kubectl label nodes k8s-node-1  app=worker-node --overwrite
kubectl label nodes k8s-node-1  tier=frontend --overwrite
kubectl label nodes k8s-node-1  environment=production  --overwrite



kubectl get pods -l 'environment in (production),database in (tier)' -n prod-01 -o wide


kubectl get nodes -l 'environment in (production),tier in (database),app in(worker-node)'

kubectl exec -ti -n prod-01 postgres-13-57666cdb5d-gxx29  -- /bin/bash