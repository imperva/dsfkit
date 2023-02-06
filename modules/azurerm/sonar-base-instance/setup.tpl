#!/bin/bash -x

set -e
set -u
set -x
cd /root || exit 1

function wait_for_network() {
    until ping -c1 www.google.com >/dev/null 2>&1; do
        echo waiting for network..;
        sleep 15;
    done
}

function install_az_cli() {
    rpm --import https://packages.microsoft.com/keys/microsoft.asc
    dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm
    dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
    dnf install azure-cli -y
    az login --identity
}

function install_deps() {
    # yum fails sporadically. So we try 3 times :(
    yum install unzip -y || yum install unzip -y || yum install unzip -y
    yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    yum install net-tools jq vim nc lsof -y

    install_az_cli

    id sonargd || useradd sonargd
    id sonarg  || useradd sonarg
    id sonarw  || useradd sonarw
    getent group sonar || groupadd sonar
    usermod -g sonar sonarw
    usermod -g sonar sonargd
}

# make this more robust
function resize_root_disk() {
    # this should run once
    echo "Resizing root fs"
    mount_device=$(findmnt --noheadings --output SOURCE /)
    device_mapper=$(realpath $mount_device)
    major_minor=$(dmsetup table $device_mapper  | awk '{print $4}')
    child_block_device=$(basename $(realpath /sys/dev/block/$major_minor))
    device=$(echo $child_block_device | grep -o [a-z]*)
    child_device_id=$(echo $child_block_device | grep -o [0-9]*)
    growpart /dev/$device $child_device_id
    pvresize /dev/$child_block_device
    vgdisplay
    lvresize -r -L +75G $mount_device
}

# Formatting and mounting the external ebs device
function attach_disk() {
    # Find device name ebs external device
    number_of_expected_disks=1
    lsblk
    DEVICES=$(lsblk --noheadings -o NAME,TYPE | grep disk | awk '{print $1}' | grep "^[a-zA-Z]")
    while [ "$(wc -w <<< $DEVICES)" -lt "$number_of_expected_disks" ]; do
        DEVICES=$(lsblk --noheadings -o NAME | grep "^[a-zA-Z]")
        echo "Waiting for all external disk attachments"
        sleep 10
    done

    for d in $DEVICES; do
        if [ "$(lsblk --noheadings -o NAME| grep $d | wc -l)" -eq 1 ]; then
            DEVICE=$d;
            break;
        fi;
    done

    if [ -z "$DEVICE" ]; then
        echo "No external device is found"
        exit 1
    fi
    
    echo "$DEVICE is the external disk"

    lsblk -no FSTYPE /dev/$DEVICE
    FS=$(lsblk -no FSTYPE /dev/$DEVICE)
    if [ "$FS" != "xfs" ]; then
        echo "/dev/$DEVICE fs is \"$FS\". Formatting it..."
        ## Formatting the device
        mkfs -t xfs /dev/$DEVICE
    fi
    
    ## Mounting the device
    STATE_DIR=/data_vol/sonar-dsf/jsonar
    mkdir -p $STATE_DIR
    DEV_UUID=$(blkid /dev/$DEVICE | cut -d ' ' -f2 | awk '{print $1}')
    if ! grep $DEV_UUID /etc/fstab &>/dev/null; then
        echo "$DEV_UUID $STATE_DIR xfs defaults 0 0" >> /etc/fstab
    fi
    mount -a
}

function install_tarball() {
    echo Downloading tarball..
    # Download intallation tarball
    TARBALL_FILE=$(basename ${az_blob})
    az storage blob download --account-name ${az_storage_account} --container-name ${az_container} --file ./$TARBALL_FILE --name ${az_blob} >/dev/null
    # /usr/local/bin/aws s3 cp s3://$${installation_s3_bucket}/$${installation_s3_key} ./$TARBALL_FILE >/dev/null

    echo Installing tarball..
    # Installing tarball
    sudo mkdir -p $DIR
    sudo tar -xf ./$TARBALL_FILE -gz -C $DIR
    rm ./$TARBALL_FILE
    sudo chown -R sonarw:sonar $DIR
}

function set_instance_fqdn() {
    instance_fqdn=$(cloud-init query -a | jq -r .ds.meta_data.imds.network.interface[0].ipv4.ipAddress[0].privateIpAddress)
    if [ -z "$instance_fqdn" ]; then
        echo "Failed to extract instance private FQDN"
        exit 1
    fi
    if [ -n "${public_fqdn}" ]; then
        instance_fqdn=$(cloud-init query -a | jq -r .ds.meta_data.imds.network.interface[0].ipv4.ipAddress[0].publicIpAddress)
        if [ "$instance_fqdn" == "null" ] || [ -z "$instance_fqdn" ]; then
            echo "Failed to extract instance public FQDN"
            exit 1
        fi
    fi
}

verlte() {
    [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
}

verlt() {
    [ "$1" = "$2" ] && return 1 || verlte $1 $2
}

function setup() {
    set_instance_fqdn
    VERSION=$(ls /opt/sonar-dsf/jsonar/apps/ -Art | tail -1)
    echo Setup sonar $VERSION

    if verlt $VERSION 4.10; then
        PRODUCT="imperva-data-security"
    else
        PRODUCT="data-security-fabric"
    fi

    sudo /opt/sonar-dsf/jsonar/apps/"$VERSION"/bin/sonarg-setup --no-interactive \
        --accept-eula \
        --jsonar-uid-display-name "${display-name}" \
        --product "$PRODUCT" \
        --newadmin-pass="${web_console_admin_password}" \
        --secadmin-pass="${web_console_admin_password}" \
        --sonarg-pass="${web_console_admin_password}" \
        --sonargd-pass="${web_console_admin_password}" \
        --jsonar-datadir=$STATE_DIR/data \
        --jsonar-localdir=$STATE_DIR/local \
        --jsonar-logdir=$STATE_DIR/logs \
        --jsonar-uid ${uuid} \
        --instance-IP-or-DNS=$instance_fqdn \
        $(test "${resource_type}" == "gw" && echo "--remote-machine") ${additional_install_parameters}
}

function set_environment_vars() {
    echo Setting environment vars
    if [ ! -f /etc/profile.d/jsonar.sh ]; then
        sudo cat /etc/sysconfig/jsonar /data_vol/sonar-dsf/jsonar/local/sonarg/sysconfig/machine | \
            sed -e 's/^/'"export "'/' | sudo tee /etc/profile.d/jsonar.sh
    fi
}

# function install_ssh_keys() {
#     echo Installing SSH keys
#     if [ "$${resource_type}" == "hub" ]; then
#         mkdir -p /home/sonarw/.ssh/
#         /usr/local/bin/aws secretsmanager get-secret-value --secret-id $${sonarw_secret_name} --query SecretString --output text > /home/sonarw/.ssh/id_rsa
#         echo "$${hub_federation_public_key}" > /home/sonarw/.ssh/id_rsa.pub
#         touch /home/sonarw/.ssh/authorized_keys
#         grep -q "$${hub_federation_public_key}" /home/sonarw/.ssh/authorized_keys || cat /home/sonarw/.ssh/id_rsa.pub > /home/sonarw/.ssh/authorized_keys
#         chown -R sonarw:sonar /home/sonarw/.ssh
#         chmod -R 600 /home/sonarw/.ssh
#         chmod 700 /home/sonarw/.ssh
#     else
#         mkdir -p /home/sonarw/.ssh
#         touch /home/sonarw/.ssh/authorized_keys
#         grep -q "$${hub_federation_public_key}" /home/sonarw/.ssh/authorized_keys || echo "$${hub_federation_public_key}" | tee -a /home/sonarw/.ssh/authorized_keys > /dev/null
#         chown -R sonarw:sonar /home/sonarw
#     fi
# }

wait_for_network
install_deps

resize_root_disk
attach_disk

STATE_DIR=/data_vol/sonar-dsf/jsonar
LAST_INSTALLATION_SOURCE=$STATE_DIR/last_install_source.txt

DIR=/opt/sonar-dsf/

if [ ! -f $LAST_INSTALLATION_SOURCE ] || [ "$(cat $LAST_INSTALLATION_SOURCE)" != "blob://${az_storage_account}/${az_container}/${az_blob}" ]; then
    install_tarball
    setup
    echo "blob://${az_storage_account}/${az_container}/${az_blob}" | sudo tee $LAST_INSTALLATION_SOURCE > /dev/null
fi

# set_environment_vars
# install_ssh_keys