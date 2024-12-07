#!/usr/bin/env bash

set -euC -o pipefail

mkdir /etc/systemd/system/telegraf.service.d

printf "setting tokens\n" >&2
cat <<EOF > /etc/systemd/system/telegraf.service.d/env.conf
[Service]
Environment=INFLUX_PROXY_TOKEN="${INFLUX_PROXY_TOKEN}"
EOF

sed -f - -i /etc/telegraf/telegraf.conf <<EOF
	/^\[agent]/ {
		a \
		hostname = "${TELEGRAF_HOST}"
	}
EOF
