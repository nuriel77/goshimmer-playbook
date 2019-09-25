#!/usr/bin/env bash
set -e

cd /opt/goshimmer-playbook
ansible-playbook -i inventory site.yml -v --tags=vhosts_config
