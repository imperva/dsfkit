variable "ec2_instance_type" {
  type      = string
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
  type      = string
}

variable "example_name" {
  type      = string
  default   = "deploy/examples/se_demo"
}

variable "web_console_cidr" {
  type = string
  default = null
}

