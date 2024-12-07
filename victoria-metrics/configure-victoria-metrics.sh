#!/usr/bin/env bash

set -euC -o pipefail

sudo useradd -s /usr/sbin/nologin victoriametrics
mkdir -p /var/lib/victoria-metrics && chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics
