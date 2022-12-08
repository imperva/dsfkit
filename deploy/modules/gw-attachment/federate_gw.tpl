#!/bin/bash -x -e
<<<<<<< HEAD

test_cmd='if ! nz -z ${dsf_gw_ip} 22 &>/dev/null; then
    echo "Encountered network issues. Can\t approach ${dsf_hub_ip}:22"
    exit 1
fi'
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${proxy_private_key} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${ssh_key_path} ec2-user@${dsf_gw_ip} -C $test_cmd
=======
>>>>>>> b77caff6dbd1f97c21a5c1191508bb7681b8d161
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${proxy_private_key} -W %h:%p ec2-user@${dsf_hub_ip}' -i ${ssh_key_path} ec2-user@${dsf_gw_ip} -C 'sudo $JSONAR_BASEDIR/bin/federated remote'
