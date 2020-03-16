#!/usr/bin/env bash
set -e

if ! /usr/bin/docker images "iotaledger/goshimmer:v0.1.3" | grep -q v0.1.3
then
    exit
fi

echo "Stopping goshimmer, please hold ..."
/bin/systemctl stop goshimmer

echo "Setting new UID and GID for shimmer user"
usermod -u 65532 shimmer
groupmod -g 65532 shimmer
chown shimmer: -R /var/lib/goshimmer

cd /opt/goshimmer-playbook \
  && git pull \
  && ansible-playbook -i inventory site.yml -v \
       --tags=goshimmer_service_file,goshimmer_config_file \
       -e overwrite=yes
