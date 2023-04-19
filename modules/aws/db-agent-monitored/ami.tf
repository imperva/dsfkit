data "aws_region" "current" {}

locals {
  ami = local.ami_map[data.aws_region.current.name]
  ssh_user = "ubuntu"
  ami_map = {
    us-east-1 = "ami-08d0c48f430986ca8"
  }
}