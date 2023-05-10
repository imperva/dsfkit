aws_region="us-west-2"
subnet_hub="subnet-xxxxx1"
subnet_hub_secondary="subnet-xxxxx2"
subnet_gw="subnet-xxxxx3"
gw_count=2
additional_tags=["Name=xx","Application=yy"]
web_console_admin_password_secret_name="xxxx1"
internal_hub_private_key_secret_name="xxxx2"
internal_hub_public_key_file_path="/home/ec2-user/hub_private.key.pub"
internal_gw_private_key_secret_name="xxxx3"
internal_gw_public_key_file_path="/home/ec2-user/gw_private.key.pub"
hub_key_pem_details = {
  private_key_pem_file_path="~/key_pair.pem",
  public_key_name="key_pair"
}
gw_key_pem_details = {
  private_key_pem_file_path="~/key_pair.pem",
  public_key_name="key_pair"
}
hub_instance_type="m6a.8xlarge"
gw_instance_type="m6a.2xlarge"

security_group_id_hub="sg-xxxx1"
security_group_id_gw="sg-xxxx2"

tarball_location = {
  s3_bucket = "tarball-bucket"
  s3_region = "us-west-2"
  s3_key    = "jsonar-4.11.0.0.0.tar.gz"
}

hub_ebs_details = {
  disk_size        = 4000
  provisioned_iops = 0
  throughput       = 125
}

gw_group_ebs_details = {
  disk_size        = 500
  provisioned_iops = 0
  throughput       = 125
}