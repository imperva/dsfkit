#!/bin/bash -x
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
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

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
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
    DEVICES=$(lsblk --noheadings -o NAME | grep "^[a-zA-Z]")
    for d in $DEVICES; do
        if [ "$(lsblk --noheadings -o NAME| grep $d | wc -l)" -eq 1 ]; then
            DEVICE=$d;
            break;
        fi;
    done

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

wait_for_network
install_deps
attach_disk
