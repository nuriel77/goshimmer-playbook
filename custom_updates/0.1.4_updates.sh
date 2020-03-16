#!/usr/bin/env bash
cd /opt/goshimmer-playbook && git pull && ansible-playbook -i inventory site.yml -v --tags=goshimmer_service_file
