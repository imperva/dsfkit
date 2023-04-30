PROXY_CMD=""
if [ -n "${gw_proxy_address}" ]; then
	PROXY_CMD='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${gw_proxy_private_ssh_key_path} -W %h:%p ${gw_proxy_ssh_user}@${gw_proxy_address}'
fi

# test_cmd='if ! nc -z ${dsf_gw_ip} 22 &>/dev/null; then
#     echo "Encountered network issues. Cant approach ${dsf_gw_ip}:22"
#     exit 1
# fi'
# ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $${PROXY_CMD:+-o ProxyCommand="$PROXY_CMD"} -i ${ssh_key_path} ${gw_ssh_user}@${dsf_gw_ip} -C $test_cmd
ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $${PROXY_CMD:+-o ProxyCommand="$PROXY_CMD"} -i ${ssh_key_path} ${gw_ssh_user}@${dsf_gw_ip} -C 'sudo $JSONAR_BASEDIR/bin/federated remote'
