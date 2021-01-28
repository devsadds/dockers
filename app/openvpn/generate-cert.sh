#!/bin/sh
VPN_CLIENT_NAME=$1
FREE_IP=$2
VPN_DOCKER_DIR=$(if [ -f "generate-cert.sh" ];then pwd;else echo 'error. not in docker-compose dir openvpn' && exit 1;fi)
VPN_CCD_DIR="${VPN_DOCKER_DIR}/configs/openvpn/ccd"
VPN_KEYS_DIR="${VPN_DOCKER_DIR}/keys"
VPN_KEYS_ISSUED_DIR="${VPN_DOCKER_DIR}/configs/openvpn/pki/issued"
VPN_KEYS_PREFIX="$3"
VPN_SUBNET="$4"

precheck () {
	if [ -z "${VPN_CLIENT_NAME}" ];then
		echo "VPN_CLIENT_NAME is empty"
		echo "Example usage  generate-cert.sh \"demo01.itc-life.ru\" \"10.17.0.11\" \"openvpn.itc-life.ru\" \"255.255.252.0\""
		exit 1
	fi
	if [ -z "${FREE_IP}" ];then
		echo "FREE_IP is empty"
		echo "Example usage  generate-cert.sh \"demo01.itc-life.ru\" \"10.17.0.11\" \"openvpn.itc-life.ru\" \"255.255.252.0\""
		exit 1
	fi
	if [ -z "${VPN_KEYS_PREFIX}" ];then
		echo "VPN_KEYS_PREFIX is empty"
		echo "Example usage  generate-cert.sh \"demo01.itc-life.ru\" \"10.17.0.11\" \"openvpn.itc-life.ru\" \"255.255.252.0\""
		exit 1
	fi
	if [ -z "${VPN_SUBNET}" ];then
		echo "VPN_SUBNET is empty"
		echo "Example usage  generate-cert.sh \"demo01.itc-life.ru\" \"10.17.0.11\" \"openvpn.itc-life.ru\" \"255.255.252.0\""
		exit 1
	fi

	if [ ! -d "${VPN_KEYS_DIR}" ];then
		mkdir -p ${VPN_KEYS_DIR}

	fi

	
}


vpn_gen_cert() {

#FREE_IP=$(cd /docker-compose/SWARM/openvpn && docker-compose run --rm openvpn ovpn_listclients | grep -ve 'status\|can' | cut -d\| -f5  | sort -n -t . -k 1,1 -k 2,2 -k 3,3 -k 4,4  > /docker-compose/SWARM/openvpn/vpn_ip.list && diff -u vpn_ip.list subnet.list | cut -d \- -f2 | sed -e 's/^[ \t]*//' | grep -ve '@@' > /docker-compose/SWARM/openvpn/free_ip.list && cat /docker-compose/SWARM/openvpn/free_ip.list | head -n1)



#grep -v -f  /docker-compose/SWARM/openvpn/vpn_ip.list /docker-compose/SWARM/openvpn/subnet.list  > /docker-compose/SWARM/openvpn/free_ip.list

if [ ! -f "${VPN_CCD_DIR}/${VPN_CLIENT_NAME}" ] && [ ! -f ${VPN_KEYS_ISSUED_DIR}/${VPN_CLIENT_NAME}.crt ]; then
echo "GENERATE CLIENT CERT FOR CLIENT  ${VPN_CLIENT_NAME} with ip ${FREE_IP}"
cd ${VPN_DOCKER_DIR}
printf "ifconfig-push ${FREE_IP} ${VPN_SUBNET}" > "${VPN_CCD_DIR}/${VPN_CLIENT_NAME}"
sleep 5;
docker-compose run --rm openvpn easyrsa build-client-full "${VPN_CLIENT_NAME}" nopass
sleep 10;
docker-compose run --rm openvpn ovpn_getclient ${VPN_CLIENT_NAME} > "${VPN_KEYS_DIR}/${VPN_KEYS_PREFIX}_${VPN_CLIENT_NAME}.conf"
echo "Cert is generated. Conf file location - ${VPN_KEYS_DIR}/${VPN_KEYS_PREFIX}_${VPN_CLIENT_NAME}.conf. IP ${FREE_IP}"
cat ${VPN_KEYS_DIR}/${VPN_KEYS_PREFIX}_${VPN_CLIENT_NAME}.conf
else

echo "Client with name ${VPN_CLIENT_NAME} already exist. Exit"
exit 1
fi

}
main () {
	precheck && vpn_gen_cert
}

main 