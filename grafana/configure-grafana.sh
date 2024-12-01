#!/usr/bin/env bash

set -euC -o pipefail

sed -f - -i /etc/grafana/grafana.ini <<EOF
	/^\[server]/ {
	  a \
		http_addr = 127.0.0.1

		a \
		domain = ${DOMAIN}

		a \
		root_url = https://%(domain)s/

		a \
		router_logging = true

		a \
		enable_gzip = true
	}

	/^\[security]/ {
		a \
		\;disable_initial_admin_creation = true

		a \
		secret_key = ${SECRET_KEY}

		a \
		cookie_secure = true

		a \
		cookie_samesite = strict
	}

	/^\[panels]/ {
		a \
		disable_sanitize_html = true
	}

	/^\[users]/ {
		a \
		allow_sign_up = false

		a \
		allow_org_create = false
	}

	/^\[auth]/ {
		a \
		disable_login_form = true

		a \
		disable_signout_menu = true
	}

	/^\[auth.anonymous]/ {
		a \
		enabled = true

		a \
		\;org_name = ${CALL}

		a \
		org_role = Viewer
	}

	/^\[auth.proxy]/ {
		a \
		\;enabled = true

		a \
		header_name = X-WEBAUTH-USER

		a \
		header_property = username

		a \
		headers = Role:X-WEBAUTH-ROLE

		a \
		enable_login_token = true

		a \
		\;whitelist = 127.0.0.1
	}

	/^\[dashboards]/ {
		a \
		default_home_dashboard_path = /var/lib/grafana/dashboards/igate.json
	}

	/^\[plugins]/ {
		a \
		allow_loading_unsigned_plugins = victoriametrics-datasource,victorialogs-datasource
	}
EOF

grafana-cli admin reset-admin-password "${ADMIN_PASSWORD}"

mkdir /var/lib/grafana/dashboards
mkdir /var/lib/grafana/plugins

wget -nv -O - https://github.com/VictoriaMetrics/victoriametrics-datasource/releases/download/v0.10.3/victoriametrics-datasource-v0.10.3.tar.gz | tar -C /var/lib/grafana/plugins -zxv
wget -nv -O - https://github.com/VictoriaMetrics/victorialogs-datasource/releases/download/v0.10.0/victorialogs-datasource-v0.10.0.tar.gz | tar -C /var/lib/grafana/plugins -zxv

# ensure that all the files and directories in /var/lib/grafana have the expected ownership
chown -R --reference /var/lib/grafana /var/lib/grafana
