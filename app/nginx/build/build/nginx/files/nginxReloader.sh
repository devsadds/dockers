#!/bin/bash
###########
sleep 3;
while true
do
 #inotifywait --exclude .swp -e create -e modify -e delete -e move -e close_write /etc/nginx/ /etc/letsencrypt/live
 inotifywait --exclude .swp  -e close_write /etc/nginx/ /etc/letsencrypt/live
 nginx -t
 if [ $? -eq 0 ]
 then
  	echo "Detected Nginx Configuration Change"
  	echo "Executing: nginx -s reload"
  	nginx -s reload
 else
 	echo "Error during check nginx config.Skip nginx reload" 
 fi
done