#!/bin/bash -x

# exec > dsf-install.log
set -x 
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

function setup() {
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
        --instance-IP-or-DNS=${instance_fqdn} \
        $(test "${dsf_type}" == "gw" && echo "--remote-machine")
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
    if [ "${dsf_type}" == "hub" ]; then
        for dir in "" "$${JSONAR_LOCALDIR}"; do
            sudo mkdir -p $${dir}/home/sonarw/.ssh/
            sudo /usr/local/bin/aws secretsmanager get-secret-value --secret-id ${sonarw_secret_name} --query SecretString --output text | sudo tee $${dir}/home/sonarw/.ssh/id_rsa > /dev/null
            sudo echo "${sonarw_public_key}" | sudo tee $${dir}/home/sonarw/.ssh/id_rsa.pub > /dev/null
            sudo touch $${dir}/home/sonarw/.ssh/authorized_keys
            sudo grep -q "${sonarw_public_key}" $${dir}/home/sonarw/.ssh/authorized_keys || sudo cat $${dir}/home/sonarw/.ssh/id_rsa.pub | sudo tee -a $${dir}/home/sonarw/.ssh/authorized_keys > /dev/null
            sudo chown -R sonarw:sonar $${dir}/home/sonarw/.ssh
            sudo chmod -R 600 $${dir}/home/sonarw/.ssh
            sudo chmod 700 $${dir}/home/sonarw/.ssh
        done
    else
        sudo mkdir -p /home/sonarw/.ssh
        sudo touch $${dir}/home/sonarw/.ssh/authorized_keys
        sudo grep -q "${sonarw_public_key}" /home/sonarw/.ssh/authorized_keys || echo "${sonarw_public_key}" | sudo tee -a /home/sonarw/.ssh/authorized_keys > /dev/null
        sudo chown -R sonarw:sonar /home/sonarw
    fi
}

STATE_DIR=/data_vol/sonar-dsf/jsonar
LAST_INSTALLATION_SOURCE=$STATE_DIR/last_install_source.txt

DIR=/opt/sonar-dsf/
set -e

until [ -d $STATE_DIR ]; do
    # curl ifconfig.me
    sleep 15
done

if [ ! -f $LAST_INSTALLATION_SOURCE ] || [ "$(cat $LAST_INSTALLATION_SOURCE)" != "s3://${installation_s3_bucket}/${installation_s3_key}" ]; then
    install_tarball
    setup
    echo "s3://${installation_s3_bucket}/${installation_s3_key}" | sudo tee $LAST_INSTALLATION_SOURCE > /dev/null
fi
set_environment_vars
install_ssh_keys
