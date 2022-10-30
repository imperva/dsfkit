[hubs]
hub     ansible_ssh_host=${hub_address}

[gws]
${gw_table}

[sonarhosts:children]
hubs
gws

[sonarhosts:vars]
ansible_ssh_private_key_file=${ssh_key_path}
ansible_ssh_user=ec2-user
sonarw_public_key=${sonarw_public_key}
sonarw_secret_name=${sonarw_secret_name}
tarball_s3_bucket=${tarball_s3_bucket}
tarball_s3_key=${tarball_s3_key}
installation_param_password=${installation_param_password}
installation_param_display_name=${installation_param_display_name}

[hubs:vars]
sonar_installation_type=hub

[gws:vars]
sonar_installation_type=gw
ansible_ssh_common_args='-o ProxyCommand="ssh -i ${ssh_key_path} -W %h:%p ec2-user@${hub_address}"'
