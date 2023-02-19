#!/bin/bash -x
set -e
set -u
set -x
cd /root || exit 1

function wait_for_network() {
    until curl www.google.com &>/dev/null; do
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

function format_unformatted_disk() {
    LUN=$1
    echo "Checking if disk with lun $LUN needs formatting"
    DEV=$(disk_from_lun $LUN)
    lsblk -no FSTYPE /dev/$disk
    FS=$(lsblk -no FSTYPE /dev/$disk)
    if [ "$FS" != "xfs" ]; then
        echo "/dev/$disk fs is \"$FS\". Formatting it..."
        ## Formatting the device
        mkfs -t xfs /dev/$disk
    fi
}

function format_unformatted_disks() {
    ## Find device name ebs external device
    number_of_expected_disks=$(($1 + 1))
    lsblk
    DISKS=$(lsblk --noheadings -o NAME,TYPE,FSTYPE | grep 'disk' | awk '{print $1}' | grep "^[a-zA-Z]")
    while [ "$(wc -w <<< $DISKS)" -lt "$number_of_expected_disks" ]; do
        DISKS=$(lsblk --noheadings -o NAME,TYPE,FSTYPE | grep 'disk' | awk '{print $1}' | grep "^[a-zA-Z]")
        echo "Waiting for all external disk attachments"
        sleep 10
    done

    format_unformatted_disk 10
    format_unformatted_disk 11
}

function disk_from_lun() {
    LUN=$1
    DEV=$(lsblk -S | grep ":$LUN *disk" | awk '{print $1}')
    if [ -z "$DEV" ]; then
        echo "No device with lun=$LUN is found"
        exit 1
    fi
    echo $DEV
}

function mount_disk() {
    MOUNT_POINT=$1
    LUN=$2
    echo "Trying to mount disk with lun $LUN to $MOUNT_POINT"
    mkdir -p $MOUNT_POINT
    DEV=$(disk_from_lun $LUN)
    DEV_UUID=$(blkid /dev/$DEV | cut -d ' ' -f2 | awk '{print $1}')
    echo "$DEV uuid is $DEV_UUID"
    if ! grep $DEV_UUID /etc/fstab &>/dev/null; then
        echo "$DEV_UUID $MOUNT_POINT xfs defaults 0 0" >> /etc/fstab
    fi
}

function mount_disks() {
    mount_disk /opt/sonar-dsf/ 10
    mount_disk /data_vol/sonar-dsf/jsonar 11
    mount -a
}

function install_tarball() {
    echo Downloading tarball..
    # Download intallation tarball
    TARBALL_FILE=$DIR/$(basename ${az_blob})
    mkdir -p $DIR
    az storage blob download --account-name ${az_storage_account} --container-name ${az_container} --file $TARBALL_FILE --name ${az_blob} >/dev/null

    echo Installing tarball..
    # Installing tarball
    sudo tar -xf $TARBALL_FILE -gz -C $DIR
    rm $TARBALL_FILE
    sudo chown -R sonarw:sonar $DIR
}

function set_instance_fqdn() {
    instance_fqdn=$(cloud-init query -a | jq -r .ds.meta_data.imds.network.interface[0].ipv4.ipAddress[0].privateIpAddress)
    if [ -z "$instance_fqdn" ]; then
        echo "Failed to extract instance private FQDN"
        exit 1
    fi
    if [ -n "${public_fqdn}" ]; then
        rg=$(cloud-init query -a | jq -r .ds.meta_data.imds.compute.resourceGroupName)
        vm=$(cloud-init query -a | jq -r .ds.meta_data.imds.compute.name)
        instance_fqdn=$(az vm show -d --name $vm --resource-group $rg --query publicIps --output tsv)
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

function install_ssh_keys() {
    echo Installing SSH keys
    mkdir -p /home/sonarw/.ssh/
    touch /home/sonarw/.ssh/authorized_keys

    # install the generated primary node public and private keys in the primary node and the secondary node
    az keyvault secret show --vault-name ${primary_node_sonarw_private_key_vault} --name ${primary_node_sonarw_private_key_secret} --query 'value' --output tsv > /home/sonarw/.ssh/id_rsa
    echo "${primary_node_sonarw_public_key}" > /home/sonarw/.ssh/id_rsa.pub

    # enable communication between a pair of primary and secondary nodes
    grep -q "${primary_node_sonarw_public_key}" /home/sonarw/.ssh/authorized_keys || echo "${primary_node_sonarw_public_key}" | tee -a /home/sonarw/.ssh/authorized_keys > /dev/null

    # enable communication between the the primary/secondary hub and the GW
    if [ "${resource_type}" == "gw" ]; then
        grep -q "${hub_sonarw_public_key}" /home/sonarw/.ssh/authorized_keys || echo "${hub_sonarw_public_key}" | tee -a /home/sonarw/.ssh/authorized_keys > /dev/null
    fi

    chown -R sonarw:sonar /home/sonarw/.ssh
    chmod -R 600 /home/sonarw/.ssh
    chmod 700 /home/sonarw/.ssh
}

function firewall_open_ports() {
    for port in ${firewall_ports}; do
        firewall-offline-cmd --add-port=$port/tcp
    done
    systemctl restart firewalld
}

wait_for_network
install_deps
firewall_open_ports || true
format_unformatted_disks 2
mount_disks

STATE_DIR=/data_vol/sonar-dsf/jsonar
LAST_INSTALLATION_SOURCE=$STATE_DIR/last_install_source.txt

DIR=/opt/sonar-dsf/

if [ ! -f $LAST_INSTALLATION_SOURCE ] || [ "$(cat $LAST_INSTALLATION_SOURCE)" != "blob://${az_storage_account}/${az_container}/${az_blob}" ]; then
    install_tarball
    setup
    echo "blob://${az_storage_account}/${az_container}/${az_blob}" | sudo tee $LAST_INSTALLATION_SOURCE > /dev/null
fi

set_environment_vars
install_ssh_keys
