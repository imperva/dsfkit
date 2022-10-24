variable "region" {
  type = string
}

variable "bucket" {
  type = string
  sensitive = true
  description = "bucket containing the installation tarball"
}

variable "tarball_path" {
  type = string
  description = "installation tarball path"
}

variable "instance_type" {
  type = string
  default = "t2.2xlarge"
  description = "Ec2 instance type"
}

variable "disk_size" {
  default = 510
  validation {
    condition     = var.disk_size >= 500
    error_message = "instance disk size must be at least 500GB"
  }
}

variable "key_pair" {
  type = string
  description = "key pair for instance"
}

variable "subnet_id" {
  type = string
}

##########################################
#   RHEL-7 AMI list per region 
## This list was created with the following command
## > for r in $(awsregions) ; do echo $r = $(aws --region $r ec2 describe-images  --filters Name=name,Values=RHEL-7.9_HVM-202205* | jq '.Images[0]."ImageId" '); done
variable "rhel79_amis_ids" {
  type = map(any)
  default = {
    af-south-1 = "ami-064aeb2452a82205f"
    ap-east-1 = "ami-0e377c3509b0a1490"
    ap-northeast-1 = "ami-0073b6113281aa32e"
    ap-northeast-2 = "ami-04adf7ab262061270"
    ap-northeast-3 = "ami-0ea15419fc3544d6a"
    ap-south-1 = "ami-01dd6bbea8d062bf3"
    ap-southeast-1 = "ami-0ee6bfca4452064bc"
    ap-southeast-2 = "ami-0bf7d72cc0b127581"
    ca-central-1 = "ami-0f1c453d5ca1059f0"
    eu-central-1 = "ami-0a62e33b5dcf31c85"
    eu-north-1 = "ami-0a32f8cdd314cf493"
    eu-south-1 = "ami-0f18d0a883583eaa9"
    eu-west-1 = "ami-06211bde2f9c725e5"
    eu-west-2 = "ami-0a8aebd46fb700315"
    eu-west-3 = "ami-07185297899bb7755"
    me-south-1 = "ami-02f76563b3f70c99d"
    sa-east-1 = "ami-08acb85e5164523d7"
    us-east-1 = "ami-004fac3d4533a2541"
    us-east-2 = "ami-0bb2449c2217cb9b0"
    us-west-1 = "ami-085733fd69e77a079"
    us-west-2 = "ami-027da4fca766221c9"
  }
}
