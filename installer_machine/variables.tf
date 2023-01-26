variable "sonar_version" {
  type    = string
  default = "4.10"
}

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
  default = "basic_deployment"
}

variable "example_type" {
  type        = string
  default     = "poc"
  description = "poc or installation, according to where your example is located in the DSFKit GitHub repository under the 'examples' directory"
}

variable "web_console_cidr" {
  type        = list(string)
  default     = null
  description = "CIDR blocks allowing DSF hub web console access"
}

variable "installer_ami_name_tag" {
  type    = string
  default = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2" # Exists on all regions
}

