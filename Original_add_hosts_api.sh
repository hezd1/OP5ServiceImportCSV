#!/bin/bash
#
# Author: christian@op5.com
# Think of this as a proof of concept, not production tested yet..
#

# API Target
URI="192.168.1.200"
USERNAME=monitor
PASSWORD=monitor

# Initial settings
HOST_TEMPLATE="default-host-template"
SERVICE_TEMPLATE="default-service"
SERVICE="PING"
COMMAND_ARGS="100,20%!500,60%"
COMMAND="check_ping"

# JSON cURL POST function
post_host() {
curl -H "content-type: application/json" -d "{\"host_name\":\"${1}\",\"alias\":\"${2}\",\"address\":\"${3}\",\"template\":\"${4}\",\"register\":\"1\",\"file_id\":\"etc\/hosts.cfg\",\"check_command\":\"check-host-alive\",\"max_check_attempts\":\"3\"}" "https://$URI/api/config/host" -u $USERNAME:$PASSWORD --write-out %{http_code} --silent --insecure --output /dev/null
}
post_service() {
curl -H "content-type: application/json" -d "{\"host_name\":\"${1}\",\"service_description\":\"${2}\",\"check_command\":\"${3}\",\"check_command_args\":\"${4}\",\"template\":\"${5}\",\"check_interval\":\"5\",\"file_id\":\"etc\/services.cfg\",\"retry_interval\":\"1\",\"max_check_attempts\":\"3\"}" "https://$URI/api/config/service" -u $USERNAME:$PASSWORD --write-out %{http_code} --silent --insecure --output /dev/null
}

# Loop through input, post URI and status output
cat $1 | while read ROW; do 
IFS=";" read HOST_NAME ADDRESS ALIAS<<EOF
$ROW
EOF
	for response in `post_host "${HOST_NAME}" "${ALIAS}" "${ADDRESS}" "${HOST_TEMPLATE}"`;do
		if [ $response == 200 ]; then
		echo "[DONE] Host: $HOST_NAME Added"
		elif [ $response == 201 ]; then
		echo "[DONE] Host: $HOST_NAME Added"
		elif [ $response == 401 ]; then
		echo "[FAILED] Not Authorized"
		elif [ $response == 400 ]; then
                echo "[FAILED] Not Authorized"
		elif [ $response == 409 ]; then
		echo "[FAILED] Host: $HOST_NAME - Already Exists"
		else
		echo "[FAILED] Host: $HOST_NAME - Unhandled Error: $r"
		fi
	done
		for response in `post_service "${HOST_NAME}" "${SERVICE}" "${COMMAND}" "${COMMAND_ARGS}" "${SERVICE_TEMPLATE}"`;do
		if [ $response == 200 ]; then
                echo "[DONE] $SERVICE Added on $HOST_NAME"
                elif [ $response == 201 ]; then
                echo "[DONE] $SERVICE Added on $HOST_NAME"
                elif [ $response == 401 ]; then
                echo "[FAILED] Not Authorized"
                elif [ $response == 400 ]; then
                echo "[FAILED] Not Authorized"
                elif [ $response == 409 ]; then
                echo "[FAILED] $SERVICE Already exist on $HOST_NAME"
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
