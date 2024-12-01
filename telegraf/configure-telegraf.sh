#!/usr/bin/env bash

metrics_id=$(influx bucket list --org "${ORG}" --name "${BUCKET}" --json | jq -r .[0].id)

printf "creating influx write token\n" >&2
telegraf_token="$(influx auth create \
	--host http://127.0.0.1:8086 \
	--org "${ORG}" \
	--write-bucket "${metrics_id}" \
	--json | jq -r '.token')"

mkdir /etc/systemd/system/telegraf.service.d

printf "setting influx write token\n" >&2
cat <<EOF > /etc/systemd/system/telegraf.service.d/env.conf
[Service]
Environment=INFLUX_TOKEN="${telegraf_token}"
Environment=INFLUX_PROXY_TOKEN="${INFLUX_PROXY_TOKEN}"
EOF

sed -f - -i /etc/telegraf/telegraf.conf <<EOF
	/^\[agent]/ {
		a \
		hostname = "${TELEGRAF_HOST}"
	}
EOF

sed -f - -i /etc/telegraf/telegraf.d/direwolf.conf <<EOF
	/^\[\[outputs\.influxdb_v2]]/ {
		a \
		organization = "${ORG}"

		a \
		bucket = "${BUCKET}"

		a \
		http_headers = {"Authorization" = "Token \${INFLUX_TOKEN}"}
	}
EOF

