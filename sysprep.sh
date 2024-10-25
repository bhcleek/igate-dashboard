#!/usr/bin/env bash

sysd_id="/etc/machine-id"
dbus_id="/var/lib/dbus/machine-id"

# Remove and recreate (and so empty) the machine-id file under /etc
if [ -e ${sysd_id} ]; then
    rm -f ${sysd_id} && touch ${sysd_id}
fi

# Remove the machine-id file under /var/lib/dbus if it is not a symlink
if [[ -e ${dbus_id} && ! -h ${dbus_id} ]]; then
    rm -f ${dbus_id}
fi
