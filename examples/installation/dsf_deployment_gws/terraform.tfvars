aws_region_gw1="eu-west-1"
aws_region_gw2="eu-central-1"

subnet_gw1="subnet-xxxxxxxxxxxxxxxx1"
subnet_gw2="subnet-xxxxxxxxxxxxxxxx2"

gw_instance_type="m5.2xlarge"

gw_group_ebs_details = {
  disk_size        = 1000
  provisioned_iops = 10000
  throughput       = 125
}

hub_sonarw_public_key = "<hub_sonarw_public_key_output>"

hub_private_ip="x.x.x.x"
hub_ssh_user="ec2-user"
hub_private_key_pem_file_path="~/dsf_ssh_key-hub-default"
