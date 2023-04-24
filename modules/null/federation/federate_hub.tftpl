verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

set -x

PROXY_CMD=""
if [ -n "${hub_proxy_address}" ]; then
    PROXY_CMD='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${hub_proxy_private_ssh_key_path} -W %h:%p ${hub_proxy_ssh_user}@${hub_proxy_address}'
fi

echo 'Running federation hub[${dsf_hub_ip}]->gw[${dsf_gw_ip}]'
# if ! nc -z ${dsf_hub_ip} 22 &>/dev/null; then
#     nc -zv ${dsf_hub_ip} 22
#     echo "Encountered network issues. Can't approach ${dsf_hub_ip}:22"
# fi

JSONAR_VERSION=$(ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $${PROXY_CMD:+-o ProxyCommand="$PROXY_CMD"} -i ${ssh_key_path} ${hub_ssh_user}@${dsf_hub_ip} 'echo $JSONAR_VERSION ')

if [ -z "$JSONAR_VERSION" ]; then
    echo JSONAR_VERSION is not defined
    exit 1
fi

echo Sonar version $JSONAR_VERSION

if verlt $JSONAR_VERSION 4.10; then
    ADDITIONAL_FLAGS=""
else
    ADDITIONAL_FLAGS="--new-remote"
fi

ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $${PROXY_CMD:+-o ProxyCommand="$PROXY_CMD"} -i ${ssh_key_path} ${hub_ssh_user}@${dsf_hub_ip} 'sudo "$JSONAR_BASEDIR"/bin/federated warehouse '$ADDITIONAL_FLAGS' ${dsf_hub_ip} ${dsf_gw_ip}'
