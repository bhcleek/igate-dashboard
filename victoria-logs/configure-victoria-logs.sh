#!/bin/bash

sudo useradd -s /usr/sbin/nologin victorialogs
mkdir -p /var/lib/victoria-logs && chown -R victorialogs:victorialogs /var/lib/victoria-logs
