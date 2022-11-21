#!/bin/bash -x -e
echo 'Running federation hub[${dsf_hub_ip}]->gw[${dsf_gw_ip}]'
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_ip} 'sudo "$JSONAR_BASEDIR"/bin/federated warehouse --new-remote ${dsf_hub_ip} ${dsf_gw_ip}'
