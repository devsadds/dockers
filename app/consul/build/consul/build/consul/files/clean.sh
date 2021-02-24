leader="$(curl http://127.0.0.1:8500/v1/status/leader | sed  's/:8300//' | sed 's/"//g')"

remove_critical(){
	consul_services_critical=$(curl http://127.0.0.1:8500/v1/health/state/critical? | jq .)
	 for row in $(echo $consul_services_critical | jq '.[].Node' | sed 's/"//g');do 
	 	echo "Exec remove  $row"

cat <<OEF> /tmp/$row_payload.json 	
{
  "Datacenter": "dc1",
  "Node": "$row"
}
OEF
	 	curl \
    		--request PUT \
    		--data @/tmp/$row_payload.json \
    		http://127.0.0.1:8500/v1/catalog/deregister
	 done
	 ls -l /tmp/ | grep json
}

main(){
	remove_critical
}

main

