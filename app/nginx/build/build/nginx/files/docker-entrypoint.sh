#!/bin/bash
###########

/nginxReloader.sh &
exec "$@"