#!/bin/bash
set -e

echo 'Running federation hub[${dsf_hub_ip}]->gw[${dsf_gw_ip}]'
# ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_ip} 'sudo "$JSONAR_BASEDIR"/bin/federated warehouse ${dsf_hub_ip} ${dsf_gw_ip}'
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_ip} 'sudo "$JSONAR_BASEDIR"/bin/federated warehouse --new-remote ${dsf_hub_ip} ${dsf_gw_ip} || sudo bash -c "set -x; cat $JSONAR_LOGDIR/sonarw/replication.log; cat $JSONAR_LOGDIR/sonarw/sonarw.log; cat $JSONAR_LOGDIR/sonarg/federated.log"'
