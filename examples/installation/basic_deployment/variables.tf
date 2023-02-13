variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "aws_profile" {
  type        = string
  description = "Aws profile name for the deployed resources"
}

variable "aws_region" {
  type        = string
  description = "Aws region for the deployed resources (e.g us-east-2)"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "subnet_hub" {
  type        = string
  description = "Aws subnet id for the primary DSF hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_hub_secondary" {
  type        = string
  description = "Aws subnet id for the secondary DSF hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw" {
  type        = string
  description = "Aws subnet id for the primary Agentless gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw_secondary" {
  type        = string
  description = "Aws subnet id for the secondary Agentless gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of Agentless gateways"
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
  description = "DSF Hub web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
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
  description = "DSF gw compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
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

variable "hub_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the hub instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the gw instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}
