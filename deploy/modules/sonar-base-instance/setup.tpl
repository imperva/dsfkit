#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
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

function install_deps() {
    # yum fails sporadically. So we try 3 times :(
    yum install unzip -y || yum install unzip -y || yum install unzip -y
    yum install net-tools jq vim -y

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    aws/install
    rm -rf aws awscliv2.zip

    useradd sonargd
    useradd sonarg
    useradd sonarw
    groupadd sonar
    usermod -g sonar sonarw
    usermod -g sonar sonargd
}

# Formatting and mounting the external ebs device
function attach_disk() {
    ## Find device name ebs external device
    number_of_expected_disks=2
    lsblk
    DEVICES=$(lsblk --noheadings -o NAME | grep "^[a-zA-Z]")
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
    TARBALL_FILE=$(basename ${installation_s3_key})
    /usr/local/bin/aws s3 cp s3://${installation_s3_bucket}/${installation_s3_key} ./$TARBALL_FILE >/dev/null

    echo Installing tarball..
    # Installing tarball
    sudo mkdir -p $DIR
    sudo tar -xf ./$TARBALL_FILE -gz -C $DIR
    rm ./$TARBALL_FILE
    sudo chown -R sonarw:sonar $DIR
}

function set_instance_fqdn() {
    instance_fqdn=$(cloud-init query -a | jq -r .local_hostname)
    if [ -z "$instance_fqdn" ]; then
        echo "Failed to extract instance private FQDN"
        exit 1
    fi
    if [ -n "${public_fqdn}" ]; then
        instance_fqdn=$(cloud-init query -a | jq -r .ds.meta_data.public_hostname)
        if [ "$instance_fqdn" == "null" ] || [ -z "$instance_fqdn" ]; then
            echo "Failed to extract instance public FQDN"
            exit 1
        fi
    fi
}

function setup() {
    set_instance_fqdn
    VERSION=$(ls /opt/sonar-dsf/jsonar/apps/ -Art | tail -1)
    echo Setup sonar $VERSION
    sudo /opt/sonar-dsf/jsonar/apps/"$VERSION"/bin/sonarg-setup --no-interactive \
        --accept-eula \
        --jsonar-uid-display-name "${display-name}" \
        --product "data-security-fabric" \
        --newadmin-pass="${admin_password}" \
        --secadmin-pass="${admin_password}" \
        --sonarg-pass="${admin_password}" \
        --sonargd-pass="${admin_password}" \
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
    if [ "${resource_type}" == "hub" ]; then
        sudo mkdir -p /home/sonarw/.ssh/
        sudo /usr/local/bin/aws secretsmanager get-secret-value --secret-id ${sonarw_secret_name} --query SecretString --output text | sudo tee /home/sonarw/.ssh/id_rsa > /dev/null
        sudo echo "${sonarw_public_key}" | sudo tee /home/sonarw/.ssh/id_rsa.pub > /dev/null
        sudo touch /home/sonarw/.ssh/authorized_keys
        sudo grep -q "${sonarw_public_key}" /home/sonarw/.ssh/authorized_keys || sudo cat /home/sonarw/.ssh/id_rsa.pub | sudo tee -a /home/sonarw/.ssh/authorized_keys > /dev/null
        sudo chown -R sonarw:sonar /home/sonarw/.ssh
        sudo chmod -R 600 /home/sonarw/.ssh
        sudo chmod 700 /home/sonarw/.ssh
    else
        sudo mkdir -p /home/sonarw/.ssh
        sudo touch /home/sonarw/.ssh/authorized_keys
        sudo grep -q "${sonarw_public_key}" /home/sonarw/.ssh/authorized_keys || echo "${sonarw_public_key}" | sudo tee -a /home/sonarw/.ssh/authorized_keys > /dev/null
        sudo chown -R sonarw:sonar /home/sonarw
    fi
}

wait_for_network
install_deps
attach_disk

STATE_DIR=/data_vol/sonar-dsf/jsonar
LAST_INSTALLATION_SOURCE=$STATE_DIR/last_install_source.txt

DIR=/opt/sonar-dsf/

if [ ! -f $LAST_INSTALLATION_SOURCE ] || [ "$(cat $LAST_INSTALLATION_SOURCE)" != "s3://${installation_s3_bucket}/${installation_s3_key}" ]; then
    install_tarball
    setup
    echo "s3://${installation_s3_bucket}/${installation_s3_key}" | sudo tee $LAST_INSTALLATION_SOURCE > /dev/null
fi

set_environment_vars
install_ssh_keys
