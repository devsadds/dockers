# Consul cluster in docker swarm

To deploy ha cluster with consul and swarm i maked docker-compose file for deploying.
I had swarm cluster with 1 node manager and 3 node workers.

Prepare:
```
 - consifure docker swarm cluster
 - install make utility
```
Our nodes

```sh
vm101 - worker
vm102 - worker
vm103 - worker
vm104 - manager 
```

Lables add for deploy our stack(exec on manager node)

```sh
docker node update --label-add consul=true vm101
docker node update --label-add consul=true vm102
docker node update --label-add consul=true vm103
```
Clone repositore with project

```sh
mkdir -p /docker/deploy/consul-server
git clone git@gitlab.com:devops_containers/dockers.git /tmp/dockers
rsync -a /tmp/dockers/app/consul/deploy/ /docker/deploy/consul-server/
cd /docker/deploy/consul-server/
```

Modify .env file if wanted
```sh
cat .env -T
```

example output
```sh
DOCKER_STACK_NAME=consul-server-1
DOCKER_IMAGE_CONSUL=devsadds/consul:1.9.3-v.1.1.5
DOCKER_NETWORK_NAME=pxc_percona_net
```

Creating network
```sh
docker network create --attachable --driver=overlay --subnet=10.15.0.0/16 pxc_percona_net
```

Deploying from manager node

```sh
make deploy
```

Show our services


```sh
docker service ls
```


```sh
ID             NAME                               MODE         REPLICAS   IMAGE                           PORTS
7wqdxp3e85tg   consul-server-1_server             global       3/3        devsadds/consul:1.9.3-v.1.1.5   *:8501->8500/tcp
cybvezqn7jea   consul-server-1_server-bootstrap   replicated   1/1        devsadds/consul:1.9.3-v.1.1.5   *:8500->8500/tcp


```

Open in web

http://192.168.122.101:8500/ui/dc1/services/consul/instances