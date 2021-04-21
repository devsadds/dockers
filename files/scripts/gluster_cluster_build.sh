#!/bin/bash

##Example run
##./gluster_cluster_build.sh --ssh_private_key_path=files/deploy-keys/convy-deploy-multi@mail/id_rsa --gluster_servers_ips=116.203.245.187,116.203.225.65 --gluster_ppa_ver=5 --gluster_role=server --gluster_store_disk=/dev/sdb --gluster_private_network_mask=10.10.1 --gluster_server_data_folder=/glusterfs --gluster_volume_name=vg0 --gluster_mountpoint=/docker-compose --gluster_clients_ips=116.203.245.188,116.203.245.187,116.203.225.65,116.203.245.244

for i in "$@"
do
case $i in
    --ssh_private_key_path=*) # ssh_private_key_path=deploy/deploy-keys/id_rsa
    SSH_PRIVATE_KEY_PATH="${i#*=}"
    shift # past argument=value
    ;;	
    --gluster_servers_ips=*) # gluster_servers_ips=116.203.245.187,116.203.225.65
    GLUSTER_SERVERS_IPS="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_ppa_ver=*) # gluster_ppa_ver=9
    GLUSTER_PPA_VER="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_role=*) # gluster_role=server
    GLUSTER_ROLE="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_store_disk=*) # gluster_store_disk=/dev/sdb
    GLUSTER_STORE_DISK="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_private_network_mask=*) # gluster_private_network_mask=10.11.0
    GLUSTER_PRIVATE_NETWORK_MASK="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_server_data_folder=*) # gluster_server_data_folder=/glusterfs
    GLUSTER_SERVER_DATA="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_volume_name=*) # gluster_volume_name=vg0
    GLUSTER_SERVER_VOLUME_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_mountpoint=*) # gluster_mountpoint=/docker-compose
    GLUSTER_MOUNTPOINT="${i#*=}"
    shift # past argument=value
    ;;
    --gluster_clients_ips=*) # gluster_clients_ips=116.203.245.188,116.203.245.187,116.203.225.65,116.203.245.244
    GLUSTER_CLIENTS="${i#*=}"
    shift # past argument=value
    ;;	
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done

SSH_OPTIONS="-i ${SSH_PRIVATE_KEY_PATH} -o StrictHostKeyChecking=no -t"
GLUSTER_HOSTS_FILE="/tmp/gluster_hosts.list"
GLUSTER_VOLUME_STATUS_FILE="/etc/gluster_${GLUSTER_SERVER_VOLUME_NAME}"
GLUSTED_PEER_PROBED_SERVER_1=$(echo "${GLUSTER_SERVERS_IPS}" | cut -d\, -f1 )
GLUSTER_PEER_PROBED_SERVER_NAME_1=$(ssh root@${GLUSTED_PEER_PROBED_SERVER_1} hostname)
GLUSTED_PEER_PROBED_SERVER_2=$(echo "${GLUSTER_SERVERS_IPS}" | cut -d\, -f2 )
GLUSTER_PEER_PROBED_SERVER_NAME_2=$(ssh root@${GLUSTED_PEER_PROBED_SERVER_2} hostname)


printf  '\n%s\n' "#Vars print#########################\n"
printf  '\n%s\n' "####################################"
printf  '\n%s\n' "GLUSTER_PRIVATE_NETWORK_MASK=$GLUSTER_PRIVATE_NETWORK_MASK"
printf  '\n%s\n' "####################################"
printf  '\n%s\n' "####################################"
printf  '\n%s\n' "###GLUSTER_SERVERS_IPS=${GLUSTER_SERVERS_IPS}"
sleep 5;


gluster_cluster_clean(){
	apt purge -y glusterfs-server 
	rm -rf /var/lib/glusterd
	wipefs --all /dev/vdb
}	



gluster_server_configure() {
echo "gluster server configure"
if [[ -f "${GLUSTER_HOSTS_FILE}" ]];then
	rm ${GLUSTER_HOSTS_FILE}
fi
printf "#GLUSTER_BLOCK_START_${GLUSTER_SERVERS_IPS}\n" >> ${GLUSTER_HOSTS_FILE}

for server in $(echo "${GLUSTER_SERVERS_IPS}" | tr -s "," " ")
do
	echo "configure server $server"
	DEBID=$(ssh ${SSH_OPTIONS} root@${server} grep 'VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
	DEBVER=$(ssh ${SSH_OPTIONS} root@${server} grep 'VERSION=' /etc/os-release | grep -Eo '[a-z]+')
	DEBARCH=$(ssh ${SSH_OPTIONS} root@${server} dpkg --print-architecture)


	ssh ${SSH_OPTIONS} root@${server} << EOF
		wget -O - https://download.gluster.org/pub/gluster/glusterfs/${GLUSTER_PPA_VER}/rsa.pub | apt-key add -
		dpkg-query -l glusterfs-server > /dev/null || (echo deb [arch=amd64] https://download.gluster.org/pub/gluster/glusterfs/${GLUSTER_PPA_VER}/LATEST/Debian/${DEBVER}/amd64/apt ${DEBVER} main > /etc/apt/sources.list.d/gluster.list  && apt update && apt install glusterfs-server -y && apt-mark hold glusterfs*)
EOF
	GLUSTER_SERVER_HOSTNAME=$(ssh root@${server} hostname)
	GLUSTER_SERVER_PRIVATE_IP=$(ssh root@${server} ip a | grep "${GLUSTER_PRIVATE_NETWORK_MASK}" | awk '{ print $2 }' | cut -d \/ -f1)
	grep -q "${GLUSTER_SERVER_HOSTNAME}" ${GLUSTER_HOSTS_FILE} || (  printf "${GLUSTER_SERVER_PRIVATE_IP} ${GLUSTER_SERVER_HOSTNAME}\n"  >> ${GLUSTER_HOSTS_FILE})
	
done

printf "#GLUSTER_BLOCK_END\n" >> ${GLUSTER_HOSTS_FILE}

for server in $(echo "${GLUSTER_SERVERS_IPS}" | tr -s "," " ")
do
	scp ${GLUSTER_HOSTS_FILE} root@${server}:/tmp/
done

for server in $(echo "${GLUSTER_SERVERS_IPS}" | tr -s "," " ")
do
	ssh ${SSH_OPTIONS} root@${server} << EOF
		grep -q "GLUSTER_BLOCK_START_${GLUSTER_SERVERS_IPS}" /etc/hosts || (cat ${GLUSTER_HOSTS_FILE} >> /etc/hosts)
EOF

done


for server in $(echo "${GLUSTER_SERVERS_IPS}" | tr -s "," " ")
do
	echo "install parted"
	ssh ${SSH_OPTIONS} root@${server} << EOF
		apt-get install parted -y || echo "ok"
EOF
	sleep 6;
	echo "exec parted -a optimal -s ${GLUSTER_STORE_DISK} mklabel gpt mkpart  primary ext4 0% 100%"
	ssh ${SSH_OPTIONS} root@${server} << EOF
		grep  -q "${GLUSTER_SERVER_DATA}" /etc/fstab || (parted -a optimal -s ${GLUSTER_STORE_DISK} mklabel gpt mkpart  primary ext4 0% 100%)
		
EOF
	sleep 6;
	echo "Exec mkfs.ext4 ${GLUSTER_STORE_DISK}1 on ${server}"
	ssh ${SSH_OPTIONS} root@${server} << EOF
		grep  -q "${GLUSTER_SERVER_DATA}" /etc/fstab || (mkfs.ext4 ${GLUSTER_STORE_DISK}1)
EOF
	sleep 6;
	ssh ${SSH_OPTIONS} root@${server} << EOF
		grep -q "${GLUSTER_SERVER_DATA}" /etc/fstab || (mkdir -p ${GLUSTER_SERVER_DATA})
EOF
	echo "Get BLKID_GLUSTER on ${server}"
	BLKID_GLUSTER=$(ssh ${SSH_OPTIONS} root@${server} blkid | grep "${GLUSTER_STORE_DISK}1" | awk '{ print $2 }' )
	echo  "BLKID_GLUSTER = ${BLKID_GLUSTER} on ${server}"
	echo "Add ${BLKID_GLUSTER} ${GLUSTER_SERVER_DATA} ext4 rw,noatime 0 to /etc/fstab on server ${server}"
	ssh ${SSH_OPTIONS} root@${server} << EOF
		grep -q "${GLUSTER_SERVER_DATA}" /etc/fstab || (echo '${BLKID_GLUSTER} ${GLUSTER_SERVER_DATA} ext4 rw,noatime 0' >> /etc/fstab)
		mount -a
EOF

done
	echo "Exec systemctl start glusterd.service on ${server} "
	ssh ${SSH_OPTIONS} root@${server} << EOF
		systemctl enable glusterd.service;
		systemctl start glusterd.service;
		sleep 5;
		systemctl start glusterd.service;
		systemctl status glusterd.service;
EOF
# From first server make peer probe second server

}

gluster_volume_create(){
	echo "exec gluster peer probe ${GLUSTER_PEER_PROBED_SERVER_NAME_2}"

ssh root@${GLUSTED_PEER_PROBED_SERVER_1} <<OEF
	gluster peer probe ${GLUSTER_PEER_PROBED_SERVER_NAME_2}
	sleep 5;
	mkdir -p ${GLUSTER_SERVER_DATA}/${GLUSTER_PEER_PROBED_SERVER_NAME_1}/gvol0
	mkdir -p ${GLUSTER_SERVER_DATA}/gvol0
OEF

ssh root@${GLUSTED_PEER_PROBED_SERVER_2} <<OEF
	gluster peer probe ${GLUSTER_PEER_PROBED_SERVER_NAME_1}
	sleep 5;
	mkdir -p ${GLUSTER_SERVER_DATA}/${GLUSTER_PEER_PROBED_SERVER_NAME_2}/gvol0
	mkdir -p ${GLUSTER_SERVER_DATA}/gvol0
OEF



echo "Gluster volume gvol0 create  on ${GLUSTED_PEER_PROBED_SERVER_1}"
ssh root@${GLUSTED_PEER_PROBED_SERVER_1} <<OEF

		if [ ! -f "${GLUSTER_VOLUME_STATUS_FILE}" ];
		then
			gluster volume create ${GLUSTER_SERVER_VOLUME_NAME} replica 2 ${GLUSTER_PEER_PROBED_SERVER_NAME_1}:${GLUSTER_SERVER_DATA}/gvol0 ${GLUSTER_PEER_PROBED_SERVER_NAME_2}:${GLUSTER_SERVER_DATA}/gvol0 force && touch ${GLUSTER_VOLUME_STATUS_FILE};
			gluster volume start ${GLUSTER_SERVER_VOLUME_NAME}
			
		else
			echo "Gluster volume name ${GLUSTER_SERVER_VOLUME_NAME} already exist. Trigger file is ${GLUSTER_VOLUME_STATUS_FILE}"
		fi
OEF
	}
echo "Gluster volume gvol0 created  on ${GLUSTED_PEER_PROBED_SERVER_1}.Sleep 20;"
sleep 20;

gluster_volume_mount_on_server(){
ssh root@${GLUSTED_PEER_PROBED_SERVER_1} <<OEF
		echo "Mount ${GLUSTER_MOUNTPOINT}"
		mkdir -p ${GLUSTER_MOUNTPOINT};
		grep -q "${GLUSTER_MOUNTPOINT}" /etc/fstab || ( echo "${GLUSTER_PEER_PROBED_SERVER_NAME_1}:/${GLUSTER_SERVER_VOLUME_NAME} ${GLUSTER_MOUNTPOINT} glusterfs defaults,_netdev 0 0" >> /etc/fstab;)
		sleep 2;
		mount -a;
OEF

ssh root@${GLUSTED_PEER_PROBED_SERVER_2} <<OEF
		mkdir -p ${GLUSTER_MOUNTPOINT};
		grep -q "${GLUSTER_MOUNTPOINT}" /etc/fstab || ( echo "${GLUSTER_PEER_PROBED_SERVER_NAME_2}:/${GLUSTER_SERVER_VOLUME_NAME} ${GLUSTER_MOUNTPOINT} glusterfs defaults,_netdev 0 0" >> /etc/fstab;)
		sleep 2;
		mount -a;
OEF

}



gluster_mount_clients() {

	echo "gluster_mount_clients on ${GLUSTER_CLIENTS}"

for server in $(echo "${GLUSTER_CLIENTS}" | tr -s "," " ")
do

	scp ${GLUSTER_HOSTS_FILE} root@${server}:/tmp/

	DEBID=$(ssh ${SSH_OPTIONS} root@${server} grep 'VERSION_ID=' /etc/os-release | cut -d '=' -f 2 | tr -d '"')
	DEBVER=$(ssh ${SSH_OPTIONS} root@${server} grep 'VERSION=' /etc/os-release | grep -Eo '[a-z]+')
	DEBARCH=$(ssh ${SSH_OPTIONS} root@${server} dpkg --print-architecture)

	ssh ${SSH_OPTIONS} root@${server} << EOF

		wget -O - https://download.gluster.org/pub/gluster/glusterfs/${GLUSTER_PPA_VER}/rsa.pub | apt-key add -
		dpkg-query -l glusterfs-client > /dev/null || (echo deb [arch=amd64] https://download.gluster.org/pub/gluster/glusterfs/${GLUSTER_PPA_VER}/LATEST/Debian/${DEBVER}/amd64/apt ${DEBVER} main > /etc/apt/sources.list.d/gluster.list  && apt update && apt install glusterfs-client -y && apt-mark hold glusterfs-client*)

		grep -q "${GLUSTER_SERVER_DATA}" /etc/hosts || (cat ${GLUSTER_HOSTS_FILE} >> /etc/hosts)
		mkdir -p ${GLUSTER_MOUNTPOINT};
		grep -q "${GLUSTER_MOUNTPOINT}" /etc/fstab || (echo "${GLUSTER_PEER_PROBED_SERVER_NAME_2}:/${GLUSTER_SERVER_VOLUME_NAME} ${GLUSTER_MOUNTPOINT} glusterfs defaults,_netdev,backupvolfile-server=${GLUSTER_PEER_PROBED_SERVER_NAME_1} 0 0" >> /etc/fstab;)
		sleep 5;
		mount -a;

EOF
done
}


main() {
	gluster_server_configure
	#gluster_volume_create
	#gluster_volume_mount_on_server
	#gluster_mount_clients
}

main