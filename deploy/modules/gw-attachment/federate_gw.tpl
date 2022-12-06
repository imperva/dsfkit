#!/bin/bash -x -e
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${proxy_private_key} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${ssh_key_path} ec2-user@${dsf_gw_ip} -C 'sudo $JSONAR_BASEDIR/bin/federated remote'
