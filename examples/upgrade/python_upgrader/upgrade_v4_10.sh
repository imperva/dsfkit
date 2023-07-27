#!/bin/bash

function download_tarball() {
    echo Downloading tarball..
    TARBALL_FILE=$(basename ${installation_s3_key})
    /usr/local/bin/aws s3 cp s3://${installation_s3_bucket}/${installation_s3_key} ./$TARBALL_FILE --region ${installation_s3_region} >/dev/null

}

function extract_tarball() {
    echo Extracting tarball..
    sudo tar -xf ./$TARBALL_FILE -gz -C $APPS_DIR
    rm ./$TARBALL_FILE
    sudo chown -R sonarw:sonar $APPS_DIR
}

function unsetEnvironmentVariables() {
    unset JSONAR_LOCALDIR JSONAR_BASEDIR JSONAR_VERSION JSONAR_DATADIR JSONAR_LOGDIR
}

function runSonargSetup() {
    sudo /imperva/apps/jsonar/apps/4.12.0.10.0/bin/sonarg-setup --no-interactive
}

function run_upgrade() {
    download_tarball
    extract_tarball
    unsetEnvironmentVariables
    runSonargSetup
}

# TODO get args

run_upgrade