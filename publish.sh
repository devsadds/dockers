#!/bin/bash

ROCKET_CHAT_URL=${SLACK_WEBHOOK}
send_message_rocket_chat () {

TEXT_HEADER=$1
TEXT_ATTACHMENT=$2

if [[ "${TEXT_ATTACHMENT}" == "" ]];then
    TEXT_ATTACHMENT="No addtioinal info"
fi
DATE_EXEC="$(date "+%d %b %Y %H:%M")"

curl -X POST --connect-timeout 5 -H 'Content-Type: application/json' --data "{\"text\":\"${TEXT_HEADER}\", \"attachments\": [{\"title\": \"Additional_info\",\"color\": \"#A52A2A\",\"text\": \"${TEXT_ATTACHMENT}\"}]}" ${ROCKET_CHAT_URL} > /dev/null

}

echo "Publish args"
echo "$1 $2 $3 $4"
send_message_rocket_chat $1 $2



