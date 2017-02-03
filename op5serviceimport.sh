#!/bin/bash
#
# Author: hezd1@GitHub
# Based on christian@op5.com's work.
# The author(s) assumes no responsibility or liability whatsoever for any failure or unexpected operation resulting from use.
#

# API Target
URI="192.168.0.100"
USERNAME=monitor
PASSWORD=monitor

# Initial settings
SERVICE_TEMPLATE="default-service"
COMMAND="check-target-alive"

# JSON cURL POST function
post_service() {
curl -H "content-type: application/json" -d "{\"host_name\":\"${1}\",\"service_description\":\"${2}\",\"check_command\":\"${3}\",\"check_command_args\":\"${4}\",\"template\":\"${5}\",\"check_interval\":\"5\",\"file_id\":\"etc\/services.cfg\",\"retry_interval\":\"1\",\"max_check_attempts\":\"3\"}" "https://$URI/api/config/service" -u $USERNAME:$PASSWORD --write-out %{http_code} --silent --insecure --output /dev/null
}

# Loop through input, post URI and status output
cat $1 | while read ROW; do
echo $ROW
# Edit these variables to match your needs.
# Host name needs to match the current host name in op5. Service will be the service name of the imported service.
IFS=";" read HOST_NAME SERVICE COMMAND_ARGS<<EOF
$ROW
EOF

        for response in `post_service "${HOST_NAME}" "${SERVICE}" "${COMMAND}" "${COMMAND_ARGS}" "${SERVICE_TEMPLATE}"`;do
        if [ $response == 200 ]; then
            echo "[DONE] $SERVICE Added on $HOST_NAME"
            elif [ $response == 201 ]; then
            echo "[DONE] $SERVICE Added on $HOST_NAME"
            elif [ $response == 401 ]; then
            echo "[FAILED] [ERROR 401] Not Authorized"
            elif [ $response == 400 ]; then
            echo "[FAILED] [ERROR 400] Bad Request"
            elif [ $response == 409 ]; then
            echo "[FAILED] [ERROR 409] $SERVICE Already exist on $HOST_NAME"
            else
            echo "[FAILED] $SERVICE on $HOST_NAME -> Unhandled Error: $r"
            fi
        done
done

changelog() {
curl "https://$URI/api/config/change?format=xml" -u $USERNAME:$PASSWORD --insecure
}
save_config() {
curl -H "content-type: application/json" -X POST "https://$URI/api/config/change" -u $USERNAME:$PASSWORD --silent --insecure
}

echo -n "Do you want to save current configuration? (y/n)"
read in
[ $in == "y" ] && echo "Saving configuration ......" && save_config && sleep 2 && exit 0 || echo "Current changes not saved:" && changelog && echo "Exiting ......" && sleep 2 && exit 0
exit 0
