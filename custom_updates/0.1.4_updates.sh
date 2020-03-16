#!/usr/bin/env bash

if /usr/bin/docker images "iotaledger/goshimmer:v0.1.3" | grep -q v0.1.3
then
    cd /opt/goshimmer-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=goshimmer_service_file,get_goshimmer_uid
fi
