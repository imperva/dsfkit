aws_profile="default"
aws_region="af-south-1"

subnet_id="subnet-xxxxxxxxxxxxxxxxx"

hub_instance_type="t3.2xlarge"
gw_instance_type="m5.2xlarge"

private_key_pem_file_path="~/key_pair.pem"
public_key_name="key_pair"

workstation_cidr=[
  "x.x.x.x/24",
  "y.y.y.y/24"
]

tarball_location = {
  s3_bucket = "tarball-bucket"
  s3_region = "af-south-1"
  s3_key    = "jsonar-4.10.0.0.0.tar.gz"
}

terraform_script_path_folder="/home/ec2-user"

ami = {
  id               = "ami-id"
  name             = "ami-name"
  username         = "ec2-user"
  owner_account_id = null
}
