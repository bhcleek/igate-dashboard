#!/usr/bin/env bash

set -euC -o pipefail

mkdir /etc/systemd/system/caddy.service.d

cat <<EOF > /etc/systemd/system/caddy.service.d/env.conf
[Service]
Environment=LOGS_DOMAIN=${LOGS_DOMAIN}
Environment=DASHBOARD_DOMAIN=${DASHBOARD_DOMAIN}
Environment=METRICS_DOMAIN=${METRICS_DOMAIN}
Environment=LOGS_TOKEN=${LOGS_TOKEN}
Environment=ADMIN_HASH="$(caddy hash-password --plaintext "${GRAFANA_ADMIN_PASSWORD}" --algorithm bcrypt)"
Environment=METRICS_TOKEN="${METRICS_TOKEN}"
EOF
