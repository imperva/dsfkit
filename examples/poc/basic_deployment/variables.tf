variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "sonar_version" {
  type        = string
  default     = "4.10.0.1"
  description = "The Sonar version to install. Sonar's supported versions are: ['4.9', '4.10', '4.10.0.1', '4.11']"
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
  description = "DSF Hub web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "database_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing dummy database access"
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "vpc_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC cidr range"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "VPC private subnet cidr range"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "VPC public subnet cidr range"
}

variable "subnet_ids" {
  type = object({
    hub_subnet_id = string
    gw_subnet_id  = string
    db_subnet_ids = list(string)
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_subnet_id != null && var.subnet_ids.gw_subnet_id != null && var.subnet_ids.db_subnet_ids != null, false)
    error_message = "Value must either be null or specified for all"
  }
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

variable "db_types_to_onboard" {
  type        = list(string)
  default     = ["RDS MySQL"]
  description = "DB types to onboard, available types are - 'RDS MySQL', 'RDS MsSQL' with data"
  validation {
    condition = alltrue([
      for db_type in var.db_types_to_onboard : contains(["RDS MySQL", "RDS MsSQL"], db_type)
    ])
    error_message = "Valid values should contain at least one of the following: 'RDS MySQL', 'RDS MsSQL'."
  }
}