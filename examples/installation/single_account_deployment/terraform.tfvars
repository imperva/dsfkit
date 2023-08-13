aws_profile="default"
workstation_cidr=["10.0.0.0/8"]
deployment_name="dev-aud-01"

additional_tags=[]
aws_region_hub="us-west-2"
subnet_hub_primary="subnet-hub-primary"
subnet_hub_secondary="subnet-hub-secondary"
hub_instance_profile_name="aud-imperva-sonar"
hub_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
web_console_admin_password_secret_name="imperva-dsf-admin"
internal_hub_private_key_secret_name="internal_gw_private_key_106_v2"
internal_hub_public_key_file_path="sonarw.pub"
security_group_ids_hub=["sg-hub"]
hub_instance_type="m6a.12xlarge"
GROUPA_gw_instance_type="m6a.2xlarge"
GROUPB_gw_instance_type="m6a.2xlarge"
GROUPC_gw_instance_type="m6a.2xlarge"
GROUPD_gw_instance_type="m6a.2xlarge"

GROUPA_aws_region="us-west-2"
GROUPA_subnet_gw="subnet-a"
GROUPA_gw_instance_profile_name="gw-primary-instance-profile"
GROUPA_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPA_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPA_web_console_admin_password_secret_name="imperva-dsf-admin"
GROUPA_internal_gw_public_key_file_path="sonarw.pub"
GROUPA_security_group_ids_gw=["sg-gwa"]
GROUPA_gw_count=1

GROUPA_ami = {
  id = "ami-id"
  name = "ami-name"
  username = "ec2-user"
  owner_account_id = "9999"
}

GROUPB_aws_region="us-west-2"
GROUPB_subnet_gw="subnet-b"
GROUPB_gw_instance_profile_name="gw-primary-instance-profile"
GROUPB_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPB_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPB_web_console_admin_password_secret_name="imperva-dsf-admin"
GROUPB_internal_gw_public_key_file_path="sonarw.pub"
GROUPB_security_group_ids_gw=["sg-b"]
GROUPB_gw_count=0

GROUPB_ami = {
  id = "ami-id"
  name = "ami-name"
  username = "ec2-user"
  owner_account_id = "9999"
}

GROUPC_aws_region="us-east-1"
GROUPC_subnet_gw="subnet-c"
GROUPC_gw_instance_profile_name="gw-primary-instance-profile"
GROUPC_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPC_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPC_internal_gw_public_key_file_path="sonarw.pub"
GROUPC_web_console_admin_password_secret_name="imperva-dsf-admin"
GROUPC_security_group_ids_gw=["sg-c"]
GROUPC_gw_count=0

GROUPC_ami = {
  id = "ami-id"
  name = "ami-name"
  username = "ec2-user"
  owner_account_id = "9999"
}

GROUPD_aws_region="us-east-1"
GROUPD_subnet_gw="subnet-d"
GROUPD_gw_instance_profile_name="gw-primary-instance-profile"
GROUPD_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPD_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPD_web_console_admin_password_secret_name="imperva-dsf-admin"
GROUPD_internal_gw_public_key_file_path="sonarw.pub"
GROUPD_security_group_ids_gw=["sg-d"]
GROUPD_gw_count=0

GROUPD_ami = {
  id = "ami-id"
  name = "ami-name"
  username = "ec2-user"
  owner_account_id = "9999"
}


tarball_location = {
  s3_bucket = "bucket"
  s3_region = "us-west-2"
  s3_key    = "jsonar-4.11.0.0.0.tar.gz"
}

hub_ebs_details = {
  disk_size        = 16000
  provisioned_iops = 5000
  throughput       = 1000
}

gw_group_ebs_details = {
  disk_size        = 500
  provisioned_iops = 2000
  throughput       = 200
}

ami = {
  id = "ami-id"
  name = "ami-name"
  username = "ec2-user"
  owner_account_id = "9999"
}
