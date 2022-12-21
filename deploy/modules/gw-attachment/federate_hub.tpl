verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

set -x 

echo 'Running federation hub[${dsf_hub_ip}]->gw[${dsf_gw_ip}]'
# if ! nc -z ${dsf_hub_ip} 22 &>/dev/null; then
#     nc -zv ${dsf_hub_ip} 22
#     echo "Encountered network issues. Can't approach ${dsf_hub_ip}:22"
# fi

JSONAR_VERSION=$(ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_ip} 'echo $JSONAR_VERSION ')

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

ssh -o ConnectionAttempts=6 -o ConnectTimeout=15 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${ssh_key_path} ec2-user@${dsf_hub_ip} 'sudo "$JSONAR_BASEDIR"/bin/federated warehouse '$ADDITIONAL_FLAGS' ${dsf_hub_ip} ${dsf_gw_ip}'
