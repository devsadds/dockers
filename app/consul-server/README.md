Lables add

```sh
docker node update --label-add consul=true vm101
docker node update --label-add consul=true vm102
docker node update --label-add consul=true vm103
```

Create network
```sh
docker network create --attachable --driver=overlay --subnet=10.15.0.0/16 pxc_percona_net

```