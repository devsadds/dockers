#!/bin/bash

docker_root="/mnt/hdd/docker"
docker_dns="10.28.0.1"
docker_default_address_pools_base="172.22.0.0/16"
docker_default_address_pools_size=24

system_prepare(){
	apt-get install nftables -y
	systemctl --now enable nftables
}

docker_stop(){
	systemctl stop docker containerd
	iptables-save > /root/iptables-docker.conf
	iptables-restore-translate -f /root/iptable-docker.conf > /root/docker.nft
	nft flush ruleset
	nft -f /root/docker.nft
	nft -s list ruleset > /etc/nftables-docker.conf
}


docker_config(){
	tee /etc/docker/daemon.json << EOF
{
  "data-root": "${docker_root}",
  "default-shm-size": "128M",
  "metrics-addr": "127.0.0.1:9323",
  "experimental": true,
  "iptables": false,
  "dns": ["${docker_dns}"],
  "mtu": 1450,
  "default-address-pools":
  [
    {
     "base": "${docker_default_address_pools_base}",
     "size": ${docker_default_address_pools_size}
    }
  ]

}
EOF


	tee /etc/systemd/system/docker.service.d/exec-start.conf << EOF


[Service]
ExecStart=
ExecStart=/usr/bin/dockerd 
EOF

	systemctl daemon-reload
}


docker_nft_tables(){

	tee /etc/nftables-docker.conf << EOF
table ip filter {
	chain INPUT {
		type filter hook input priority 0; policy accept;
	}

	chain FORWARD {
		type filter hook forward priority 0; policy accept;
		counter jump DOCKER-USER
		counter jump DOCKER-ISOLATION-STAGE-1
		oifname "docker0" ct state established,related counter accept
		oifname "docker0" counter jump DOCKER
		iifname "docker0" oifname != "docker0" counter accept
		iifname "docker0" oifname "docker0" counter accept
	}

	chain OUTPUT {
		type filter hook output priority 0; policy accept;
	}

	chain DOCKER {
	}

	chain DOCKER-ISOLATION-STAGE-1 {
		iifname "docker0" oifname != "docker0" counter jump DOCKER-ISOLATION-STAGE-2
		counter return
	}

	chain DOCKER-ISOLATION-STAGE-2 {
		oifname "docker0" counter drop
		counter return
	}

	chain DOCKER-USER {
		counter return
	}
}
table ip nat {
	chain PREROUTING {
		type nat hook prerouting priority -100; policy accept;
		fib daddr type local counter jump DOCKER
	}

	chain INPUT {
		type nat hook input priority 100; policy accept;
	}

	chain POSTROUTING {
		type nat hook postrouting priority 100; policy accept;
		oifname != "docker0" ip saddr ${docker_default_address_pools_base} counter masquerade
	}

	chain OUTPUT {
		type nat hook output priority -100; policy accept;
		ip daddr != 127.0.0.0/8 fib daddr type local counter jump DOCKER
	}

	chain DOCKER {
		iifname "docker0" counter return
	}
}

EOF

	#curl -qs https://gitlab.com/devops_containers/dockers/-/raw/master/files/nftables/nftables-docker.conf -o /etc/nftables-docker.conf 
	nft -f /etc/nftables-docker.conf
	systemctl start docker containerd
}


docker_aliases_nft_edit(){
	echo "Edit aliases for user $(whoami)"
	if [[ "$(whoami)" == "root" ]];then
		path_bashrc="/$(whoami)/.bashrc"
	else
		path_bashrc="/home/$(whoami)/.bashrc"
	fi
	if [[ ! -f "${path_bashrc}" ]];then touch "${path_bashrc}";fi
	grep -q "sudo nft -f /etc/nftables-docker.conf && sudo systemctl start docker"  "${path_bashrc}" && echo "alias docker_on exist" ||  echo "alias docker_on='sudo nft -f /etc/nftables-docker.conf && sudo systemctl start docker'" >> "${path_bashrc} "
	grep -q "alias docker_off='sudo systemctl stop docker containerd && sudo nft -f /etc/nftables.conf && sudo ip l d docker0'" "${path_bashrc}" && echo "alias docker_off exist" || echo "alias docker_off='sudo systemctl stop docker containerd && sudo nft -f /etc/nftables.conf && sudo ip l d docker0'" >> "${path_bashrc}"
}

finish_stage(){
	echo "finished"
}

main(){
	system_prepare
	docker_stop
	docker_config
	docker_nft_tables
	docker_aliases_nft_edit
	finish_stage
}

main