# Dockers





# Plugins


## weaveworks/net-plugin

Configure firewall

```sh
iptables -A INPUT -p tcp --dport 6783 -j ACCEPT
iptables -A INPUT -p udp --dport 6783 -j ACCEPT
iptables -A INPUT -p udp --dport 6784 -j ACCEPT
iptables -A INPUT -p tcp --dport 6781 -j ACCEPT
iptables -A INPUT -p tcp --dport 6782 -j ACCEPT

```

Install 
```sh
docker plugin install weaveworks/net-plugin:2.8.1
```

curl -L git.io/weave -o /usr/local/bin/weave;  chmod a+x /usr/local/bin/weave
```sh
docker plugin install --alias weaveworks/net-plugin:2.8.1 --grant-all-permissions --disable weaveworks/net-plugin:2.8.1 ;
docker plugin disable weaveworks/net-plugin:2.8.1
docker plugin set weaveworks/net-plugin:2.8.1 WEAVE_PASSWORD=Cbrt32456 WEAVE_MULTICAST=1 WEAVE_MTU=1376 IPALLOC_RANGE=10.148.0.0/14 && docker plugin enable weaveworks/net-plugin:2.8.1



mkdir -p /var/lib/docker/plugins/weaveworks_net_plugin_2_8_1
WEAVEEXEC_DOCKER_ARGS='-e WEAVE_CNI_PLUGIN_DIR=/var/lib/docker/plugins/weaveworks_net_plugin_2_8_1' weave setup
WEAVEEXEC_DOCKER_ARGS='-e WEAVE_CNI_PLUGIN_DIR=/var/lib/docker/plugins/weaveworks_net_plugin_2_8_1' weave launch  --ipalloc-range  192.77.0.0/16

docker plugin install store/weaveworks/net-plugin:2.8.1
docker plugin disable store/weaveworks/net-plugin:2.8.1
docker plugin set store/weaveworks/net-plugin:2.8.1 WEAVE_PASSWORD=SomePassword
docker plugin set store/weaveworks/net-plugin:2.8.1 WEAVE_MULTICAST=1
docker plugin enable store/weaveworks/net-plugin:2.8.1

```


Configure

```sh
docker plugin set weaveworks/net-plugin:2.8.1 IPALLOC_RANGE=192.77.0.0/16
```

Create network
```sh
docker network create --attachable --driver=weaveworks/net-plugin:2.8.1 --subnet=10.10.0.0/22  pxc_percona_net
docker network create --attachable --driver=weaveworks/net-plugin:2.8.1  pxc_percona_net

```