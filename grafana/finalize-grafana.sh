#!/usr/bin/env bash

set -euC -o pipefail

printf "creating influx read token\n" >&2
metrics_id=$(influx bucket list --org "${ORG}" --name "${BUCKET}" --json | jq -r .[0].id)
grafana_token="$(influx auth create \
	--host http://127.0.0.1:8086 \
	--org "${ORG}" \
	--read-bucket "${metrics_id}" \
	--json | jq -r '.token')"

printf "setting influx read token\n" >&2
sed -f - -i /etc/grafana/provisioning/datasources/telegraf.yaml <<EOF
	/__BUCKET__/ {
		s/__BUCKET__/${BUCKET}/
	}

	/__TOKEN__/ {
		s:__TOKEN__:${grafana_token}:
	}
EOF
