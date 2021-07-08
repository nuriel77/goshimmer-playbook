#!/usr/bin/env bash
set -e

echo "Updating config file with new entry node"

cd /opt/goshimmer-playbook

ansible-playbook -i inventory \
  site.yml \
  -v --tags goshimmer_config_file \
  -e overwrite=yes
