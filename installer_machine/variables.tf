variable "ec2_instance_type" {
  type    = string
  default = "t2.small"
}

variable "_1_aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "_2_aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "_3_aws_region" {
  type = string
}

variable "example_name" {
  type    = string
  default = "poc/basic_deployment"
}

variable "web_console_cidr" {
  type    = string
  default = null
}


variable "installer_ami_name_tag" {
  type    = string
  default = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2" # Exists on all regions
}

