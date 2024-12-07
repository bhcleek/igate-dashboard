# Summary

Creates a machine image that exposes a dashboard for an APRS IGate using [Dire Wolf's](https://github.com/wb2osz/direwolf) logs. This may be for you if you want to expose your APRS IGate's logs to interested hams or others, or if you merely want to make it accessible to yourself remotely.

This does not create or configure an APRS IGate - this project is about making your IGate observable.

# Building

Build the machine image using [Packer](https://packer.io): `packer build -var "digitalocean_token=$DIGITALOCEAN_TOKEN" -var-file keys.auto.pkvars.hcl igate.pkr.hcl`.

Several variables will be used during the building of the image to configure various aspects. See `igate.pkr.hcl` for a complete list and their default values.

The default values are suitable for me, but likely are not suitable for anyone that wants to reuse this repository to create their own igate dashboard. The defaults can be overridden on the command line, in a `var-file`, or a combination thereof. See https://developer.hashicorp.com/packer/guides/hcl/variables#assigning-variables for more information.

While this repository contains an encrypted file with some values for variables that do not have defaults, unless you are me, you should choose and use your own.

## variables
`fluent_shared_key` is used to protect access to the fluent-bit server via the Caddy reverse proxy. Required.

`grafana_admin_password` is used as Grafana's [`admin_password`](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#admin_password) configuration value. Unsurprisingly, it is used as the password for the default Grafana admin. Defaults to `admin`.

`grafana_secret_key` is used as Grafana's [`secret_key`](https://grafana.com/docs/grafana/latest/setup-grafana/configure-grafana/#secret_key) configuration value. It is used to sign some Grafana datasource settings like secrets and passwords. Required.

`telegraf_token` is used as the token to authenticate requests proxied through Caddy to Telegraf for POSTing metrics.

`digitalocean_token` is the token to authenticate with the DigitalOcean API used with the [DigitalOcean builder](https://developer.hashicorp.com/packer/integrations/digitalocean/digitalocean/latest/components/builder/digitalocean#required:) to provision the image. Required.

`dashboard_domain` is the domain of the dashboard itself. Defaults to `dashboard.k7bcx.com`, but that is most certainly suitable only for me; you should choose your own value.

`logs_domain` is the domain to which logs will be sent from the igate. Defaults to `logs.k7bcx.com`, but that is most certainly suitable only for me; you should choose your own value.

`metrics_domain` is the domain on which to listen for metrics. Defaults to `metrics.k7bcx.com`, but that is most certainly suitable only for me; you should choose your own value.

`call` is the call sign of the igate. This is used to configure the org in Grafana and to identify IBEACON messages from the igate in order to extract the metrics.

# How the Dashboard Works

The dashboards consists of several components:
* A Caddy webserver to handle TLS and authentication; Caddy proxies all requests that originate outside of the dashboard itself.
* Fluent Bit to handle processing direwolf logs from the APRS IGate.
* Telegraf for proxying metrics.
* VictoriaMetrics to persist the metrics.
* VictoriaLogs to persist both raw direwolf logs and the log of parsed packets.
* Frontail to expose the IGate's logs on the Grafana dashboard.
* Grafana to provide a nice UI for the metrics and logs.

A Caddy webserver reverse proxies to Grafana, VictoriaMetrics, and VictoriaLogs, Fluent Bit, and Telegraf. Caddy also handles provisioning and renewing LetsEncrypt certificates as needed.

The IGate sends its logs to Fluent Bit via the [HTTP](https://docs.fluentbit.io/manual/pipeline/outputs/http) output plugin to the `logs_domain`. Similarly, the IGate sends its metrics to Telegraf to the `metrics_domain`. Caddy ensures the communication is authenticated and encrypted and reverse proxies the connections to Fluent Bit's [HTTP](https://docs.fluentbit.io/manual/pipeline/inputs/http) input plugin and Telegraf's [influxdb_v2_listenter](https://github.com/influxdata/telegraf/blob/master/plugins/inputs/influxdb_v2_listener/README.md) plugin.

Fluent Bit ingests the logs from direwolf and writes them to a local file.

The Fluent Bit and Telegraf configurations on the igate can be seen in my [Ansible playbooks](https://github.com/bhcleek/ansible-playbooks). The best starting point to review is the [aprs-igate role](https://github.com/bhcleek/ansible-playbooks/tree/main/roles/aprs-igate).

Grafana exposes the metrics and direwolf logs. The latter is exposed as a stream in the browser via Frontail. The logs can be tailed directly or in an iframe on the dashboard.

# Credit

Thanks to https://github.com/nayrnet/igate for the inspiration. The examples of it provided for the grafana dashboard and the tools to construct it paved the way for this project.
