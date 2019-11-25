#!/usr/bin/env bash
# Changes to cli options
# Only update if version 26e99d8 found on system

if [ -e /etc/default/goshimmer ]
then
    CONFIG=/etc/default/goshimmer
elif [ -e /etc/sysconfig/goshimmer ]
then
    CONFIG=/etc/sysconfig/goshimmer
else
    >&2 echo "Missing goshimmer configuration file"
    exit 1
fi

if /usr/bin/docker images iotaledger/goshimmer | grep -q 26e99d8
then
    sed -i 's/-node-enable-plugins/--node.enablePlugins/g' "$CONFIG"
    sed -i 's/-node-disable-plugins/--node.disablePlugins/g' "$CONFIG"
    sed -i 's/-autopeering-entry-nodes/--autopeering.entryNodes/g' "$CONFIG"
    /bin/systemctl restart goshimmer
fi
