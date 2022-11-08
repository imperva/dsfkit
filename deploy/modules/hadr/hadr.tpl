#!/bin/bash -x
set -e

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_primary_public_ip} -C 'sudo $JSONAR_BASEDIR/bin/arbiter-setup setup-2hadr-replica-set --ipv4-address-main=${dsf_hub_primary_private_ip} --ipv4-address-dr=${dsf_hub_secondary_private_ip} --replication-sync-interval=1'
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_secondary_public_ip} -C 'sudo $JSONAR_BASEDIR/bin/arbiter-setup restart-secondary-services'
sleep 120
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_primary_public_ip} -C 'sudo $JSONAR_BASEDIR/bin/arbiter-setup check-2hadr-replica-set'