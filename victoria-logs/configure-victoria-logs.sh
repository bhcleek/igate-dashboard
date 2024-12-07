#!/usr/bin/env bash

set -euC -o pipefail

sudo useradd -s /usr/sbin/nologin victorialogs
mkdir -p /var/lib/victoria-logs && chown -R victorialogs:victorialogs /var/lib/victoria-logs
