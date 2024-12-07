#!/usr/bin/env bash

##############################################################################
# Description: a simple script to metrics and log data from an old instance to
#              a new instance. 
#
# Usage: ./migrate.sh OLD NEW
#
# OLD and NEW are expected to be host names or IPs.
##############################################################################
set -euC -o pipefail

src=$1
dest=$2

printf "syncing host keys\n" >&2
ssh-keyscan "${src}" >> ~/.ssh/known_hosts
ssh-keyscan "${dest}" >> ~/.ssh/known_hosts
ssh "root@${src}" 'mkdir ~/.ssh' || true
ssh "root@${src}" "ssh-keyscan ${dest} >> ~/.ssh/known_hosts"

printf "stopping victoria-logs on %s\n" "${dest}" >&2
ssh "root@${dest}" systemctl stop victoria-logs

printf "stopping victoria-logs on %s\n" "${src}" >&2
ssh "root@${src}" systemctl stop victoria-logs

printf "syncing log data\n" >&2
ssh -A "root@${src}" rsync -avhz --delete --progress /var/lib/victoria-logs/ "root@${dest}:/var/lib/victoria-logs"

printf "starting victoria-logs on %s\n" "${dest}"
ssh "root@${dest}" systemctl start victoria-logs



printf "stopping victoria-metrics on %s\n" "${dest}" >&2
ssh "root@${dest}" systemctl stop victoria-metrics

printf "stopping victoria-metrics on %s\n" "${src}" >&2
ssh "root@${src}" systemctl stop victoria-metrics

printf "syncing metric data\n" >&2
ssh -A "root@${src}" rsync -avhz --delete --progress /var/lib/victoria-metrics/ "root@${dest}:/var/lib/victoria-metrics"

printf "starting victoria-metrics on %s\n" "${dest}"
ssh "root@${dest}" systemctl start victoria-metrics
