variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "aws_profile_hub" {
  type        = string
  description = "Aws profile name for the DSF hub account"
}

variable "aws_region_hub" {
  type        = string
  description = "Aws region for the DSF hub (e.g us-east-2)"
}

variable "subnet_hub" {
  type        = string
  description = "Aws subnet id for the DSF hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "aws_profile_gw" {
  type        = string
  description = "Aws profile name for the DSF agentless gw account"
}

variable "aws_region_gw" {
  type        = string
  description = "Aws region for the DSF agentless gw (e.g us-east-1)"
}

variable "subnet_gw" {
  type        = string
  description = "Aws subnet id for the DSF agentless gw (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of agentless gateways"
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

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/80035.htm"
}

# variable "vpc_ip_range" {
#   type        = string
#   default     = "10.0.0.0/16"
#   description = "VPC cidr range"
# }

# variable "private_subnets" {
#   type        = list(string)
#   default     = ["10.0.1.0/24", "10.0.2.0/24"]
#   description = "VPC private subnet cidr range"
# }

# variable "public_subnets" {
#   type        = list(string)
#   default     = ["10.0.101.0/24", "10.0.102.0/24"]
#   description = "VPC public subnet cidr range"
# }

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 500
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
  description = "DSF gw compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "hub_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF hub"
}

variable "gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF gw"
}

variable "hub_ami_name" {
  type        = string
  default     = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  description = "Ec2 AMI name for the DSF hub"
}

variable "gw_ami_name" {
  type        = string
  default     = "RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2"
  description = "Ec2 AMI name for the DSF gw"
}

variable "hub_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the hub instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the gw instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}