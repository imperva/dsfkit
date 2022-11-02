variable "ec2_instance_type" {
  type      = string
  default = "t2.small"
}

variable "aws_secret_access_key" {
  type      = string
  sensitive = true
}

variable "aws_access_key_id" {
  type      = string
  sensitive = true
}

variable "aws_region" {
  type      = string
}

variable "example_name" {
  type      = string
  default   = "se_demo"
}

variable "web_console_cidr" {
  type = string
  default = null
}

