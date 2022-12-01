#!/bin/bash -x -e
test_cmd='if ! nz -z ${dsf_gw_ip} 22 &>/dev/null; then
    echo "Encountered network issues. Can\t approach ${dsf_hub_ip}:22"
    exit 1
fi'
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${gw_ssh_key_path} ec2-user@${dsf_gw_ip} -C $test_cmd
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${gw_ssh_key_path} ec2-user@${dsf_gw_ip} -C 'sudo $JSONAR_BASEDIR/bin/federated remote'
