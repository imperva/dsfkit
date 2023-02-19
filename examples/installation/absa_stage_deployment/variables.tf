variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "aws_profile_hub" {
  type        = string
  description = "Aws profile name for the DSF hub account"
}

variable "aws_region_hub" {
  type        = string
  description = "Aws region for the DSF hub (e.g us-east-2)"
}

variable "aws_profile_gw" {
  type        = string
  description = "Aws profile name for the DSF agentless gw account"
}

variable "aws_region_gw" {
  type        = string
  description = "Aws region for the DSF agentless gw (e.g us-east-1)"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "subnet_hub" {
  type        = string
  description = "Aws subnet id for the primary DSF hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw" {
  type        = string
  description = "Aws subnet id for the primary Agentless gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
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

variable "hub_ami_name" {
  type        = string
  default     = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  description = "Ec2 AMI name for the DSF hub"
}

variable "gw_ami_name" {
  type        = string
  default     = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  description = "Ec2 AMI name for the Agentless gateway"
}

variable "private_key_pem_file_path" {
  type = string
  description = "Private key file path used to ssh to the Hub and Gateway EC2s."
}

variable "public_key_name" {
  type = string
  description = "Public key name used to ssh to the Hub and Gateway EC2s."
}
