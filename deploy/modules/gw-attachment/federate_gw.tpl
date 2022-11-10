#!/bin/bash
set -e

ssh -o ConnectionAttempts=10 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${ssh_key_path} ec2-user@${dsf_gw_ip} -C 'sudo $JSONAR_BASEDIR/bin/federated remote'
