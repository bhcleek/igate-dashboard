#!/usr/bin/env bash

set -euC -o pipefail

sudo useradd -s /usr/sbin/nologin victoriaagent
mkdir -p /var/lib/victoria-agent && chown -R victoriaagent:victoriaagent /var/lib/victoria-agent
