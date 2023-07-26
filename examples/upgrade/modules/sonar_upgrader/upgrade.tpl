
function slp(){
    if [ -z "$1" ]
    then
        sleep 10
    else
        sleep $1
    fi
}


function upgrade_gw(){
    echo "----- upgrade gw $1"
    echo "take backup of the gateway"
    slp 3
    echo "----- upgrade gateway $1"
    echo "download tarball ${target_version}"
    slp 3
    echo "run upgrade script"
    echo "----- run post upgrade script"
    slp 3
    echo "----- move traffic to $1"
    slp 3
}

function print_gw(){
    json=$1
    echo $json
    for item in $(echo "$json" | jq -c '.[]'); do
        # Extract values using jq
        id=$(echo "$item" | jq -r '.id')
        ssh_key=$(echo "$item" | jq -r '.ssh_key')

        # Use the extracted values
        echo "ID: $id"
        echo "SSH Key: $ssh_key"
        echo "---"
    done
}

echo "********** Reading Inputs ************"
slp 5
echo "gw_list:"
print_gw '${target_gws_by_id}'
echo "hub list:"
print_gw '${target_hubs_by_id}'
echo "target_version ${target_version}"
echo "custom_validations_scripts ${custom_validations_scripts}"

echo "********** Start ************"
slp 5
echo "----- pre-flight check"
echo "check the version of the gateway"
echo "version: 4.9"
echo "check the version of the hub"
echo "version: 4.9"
echo "compare the version of the gateway and hub and target version: ${target_version}"
echo "check disk space"
slp
echo "----- custom checks"
echo "run: ${custom_validations_scripts}"
slp
echo "----- upgrade gw secondary"
upgrade_gw "secondary"
echo "----- upgrade gw primary"
upgrade_gw "primary"
echo "********** End ************"





