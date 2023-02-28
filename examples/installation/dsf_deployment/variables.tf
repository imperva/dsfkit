variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "aws_profile" {
  type        = string
  description = "AWS profile name for the deployment"
}

variable "aws_region" {
  type        = string
  description = "AWS region for the deployment (e.g us-east-2)"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket DSF installation location"
  default     = null
}

variable "subnet_id" {
  type        = string
  description = "Aws subnet id for the primary DSF node (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of agentless gateways"
  validation {
    condition     = var.gw_count > 0
    error_message = "The gw_count value must be greater than 0."
  }
}

variable "web_console_admin_password" {
  sensitive   = true
  type        = string
  default     = null # Random
  description = "Admin password (Random generated if not set)"
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowing DSF hub web console access"
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 250
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "gw_group_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF gw compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 75
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "hub_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF Hub"
}

variable "gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the Agentless gateway"
}

variable "ami" {
  type = object({
    id               = string
    name             = string
    username         = string
    owner_account_id = string
  })
  description = "Aws machine image filter details. Set to null if you wish to use the recommended image. The latest image that answers to this filter is chosen. Set owner_account_id to null to get the current account. username is the ami username (mandatory)."
  default     = null
}

variable "private_key_pem_file_path" {
  type = string
  description = "Private key file path used to ssh to the Hub and Gateway EC2s."
}

variable "public_key_name" {
  type = string
  description = "Public key name used to ssh to the Hub and Gateway EC2s."
}

variable "terraform_script_path_folder" {
  type = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF hub and DSF agentless GW instances. Use '.' to represent the instance home directory"
  default = null
  validation {
    condition = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder can not be an empty string"
  }
}
