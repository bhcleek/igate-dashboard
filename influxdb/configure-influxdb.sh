#!/usr/bin/env bash

set -euC -o pipefail

printf "starting influxdb\n" 2>&1
systemctl restart influxdb

printf "setting up influxdb2\n" 2>&1
count=0
until influx setup  \
	--username "${USERNAME}" \
	--password "${PASSWORD}" \
	--org "${ORG}" \
	--bucket "${BUCKET}" \
	--force
do
	if [[ "$((count))" -ge "60" ]]
	then
		exit 1
	fi

	printf "retrying...\n" >&2
	count=$((count+1))
	sleep 2
done


printf "setting org all access API token\n" 2>&1
influx auth create \
	--all-access \
	--host http://127.0.0.1:8086 \
	--org "${ORG}" \
	--json

# TODO(bc): store the operator token
# TODO(bc): remove the config that uses the operator token
# TODO(bc): store the all-access token

metrics_id=$(influx bucket list --org "${ORG}" --name "${BUCKET}" --json | jq -r .[0].id)

# TODO(bc): use the all-access token to create the tokens for grafana and telegraf
