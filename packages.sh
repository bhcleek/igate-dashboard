#!/bin/bash

set -euC -o pipefail

export DEBIAN_FRONTEND=noninteractive

printf "=====> waiting for cloud-init to finish\n" >&2
cloud-init status --wait

printf "=====> updating repositories\n" >&2
apt-get --yes --quiet update

printf "=====> upgrading base\n" >&2
apt-get --yes --quiet  -o Dpkg::Options::=--force-confnew upgrade

printf "=====> adding repositories\n" >&2

apt-get --yes --quiet install apt-transport-https software-properties-common wget

if [[ ! -d /etc/apt/keyrings ]]; then
	mkdir /etc/apt/keyrings
	chmod 0755 /etc/apt/keyrings
fi

wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor > /etc/apt/keyrings/grafana.gpg
printf "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main\n" | tee -a /etc/apt/sources.list.d/grafana.list

wget -q -O - https://repos.influxdata.com/influxdata-archive_compat.key | gpg --dearmor > /etc/apt/keyrings/influxdb.gpg
source /etc/lsb-release
printf "deb [signed-by=/etc/apt/keyrings/influxdb.gpg] https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable\n" | tee /etc/apt/sources.list.d/influxdb.list

wget -q -O - https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor > /etc/apt/keyrings/caddy.gpg
for type in deb deb-src; do
	printf "%s [signed-by=/etc/apt/keyrings/caddy.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main\n" "$type" | tee -a /etc/apt/sources.list.d/caddy.list
done

# TODO(bc): replace fluent-bit with Vector. Keep fluent-bit on the sender,
# because fluent-bit wins CPU vs Vector. Vector has a Fluent source that can be
# used to handle records sent with fluent-bit's forward plugin.
wget -q -O - https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /etc/apt/keyrings/fluentbit.gpg
printf "deb [signed-by=/etc/apt/keyrings/fluentbit.gpg] https://packages.fluentbit.io/ubuntu/${DISTRIB_CODENAME} ${DISTRIB_CODENAME} main\n" | tee -a /etc/apt/sources.list.d/fluentbit.list

apt-get --yes --quiet update

printf "=====> installing packages\n" >&2
apt-get --yes --quiet install nodejs npm telegraf influxdb2 grafana fluent-bit caddy jq

#printf "=====> installing snap\n" >&2
#snap install core
#snap refresh core
#
#printf "=====> installing certbot\n" >&2
#snap install --classic certbot
#ln -s /snap/bin/certbot /usr/bin/certbot

printf "=====> reloading systemd daemon\n" >&2
systemctl daemon-reload

printf "=====> enabling fluent-bit service\n" >&2
systemctl enable fluent-bit

printf "=====> enabling grafana-server service\n" >&2
systemctl enable grafana-server

printf "=====> installing npx\n" >&2
npm install -g --production npx

printf "=====> installing frontail\n" >&2
npm install -g --production frontail@4.9.2
