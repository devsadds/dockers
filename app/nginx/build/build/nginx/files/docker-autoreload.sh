#!/bin/sh

# This will watch the /spcgeonode-certificates folder and run nginx -s reload whenever there are some changes.
# We use this to reload nginx config when certificates changed.

# inspired/copied from https://github.com/kubernetes/kubernetes/blob/master/examples/https-nginx/auto-reload-nginx.sh

while true
do
        inotifywait -e create -e modify -e delete -e move -r --exclude "\\.certbot\\.lock|\\.well-known" "/etc/nginx"
        echo "Changes noticed in /spcgeonode-certificates"

        echo "Waiting 5s for additionnal changes"
        sleep 5


        # Test nginx configuration
        nginx -t
        # If it passes, we reload
        if [ $? -eq 0 ]
        then
                echo "Configuration valid, we reload..."
                nginx -s reload
        else
                echo "Configuration not valid, we do not reload."
        fi
done