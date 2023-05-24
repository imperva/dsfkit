variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "enable_dsf_hub" {
  type        = bool
  default     = true
  description = "Provision DSF Hub. Required if you wish to provision Agentless Gateways"
}

variable "enable_dsf_dam" {
  type        = bool
  default     = true
  description = "Provision DSF MX. Required if you wish to provision Agent Gateways"
}

variable "enable_dsf_dra" {
  type        = bool
  default     = true
  description = "Provision DSF DRA. Required if you wish to provision DRA analytics"
}

variable "agentless_gw_count" {
  type        = number
  default     = 1
  description = "Number of DSF Agentless Gateways. Provisioning Agentless Gateways requires DSF HUB"
}

variable "agent_gw_count" {
  type        = number
  default     = 1
  description = "Number of DSF Agent Gateways. Provisioning Agent Gateways requires DSF MX"
}

variable "dra_analytics_server_count" {
  type        = number
  default     = 1
  description = "Number of DRA analytics servers. Provisioning Agentless Gateways requires a DRA admin"
}

variable "password" {
  sensitive   = true
  type        = string
  default     = null # Random
  description = "Password for all relevant users and components including internal communication (DRA instances, Agent and Agentless Gateways, MX and Hub) and also to MX and DSF Hub web console (Random generated if not set)"
}

##############################
#### networking variables ####
##############################
variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub and MX web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
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
    hub_subnet_id                    = string
    hub_secondary_subnet_id          = string
    agentless_gw_subnet_id           = string
    agentless_gw_secondary_subnet_id = string
    mx_subnet_id                     = string
    agent_gw_subnet_id               = string
    admin_subnet_id                  = string
    analytics_subnet_id              = string
    db_subnet_ids                    = list(string)
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_subnet_id != null && var.subnet_ids.hub_secondary_subnet_id != null && var.subnet_ids.agentless_gw_subnet_id && var.subnet_ids.agentless_gw_secondary_subnet_id != null && var.subnet_ids.mx_subnet_id != null && var.subnet_ids.agent_gw_subnet_id != null && var.subnet_ids.admin_subnet_id != null && var.subnet_ids.analytics_subnet_id != null && var.subnet_ids.db_subnet_ids != null, false)
    error_message = "Value must either be null or specified for all"
  }
}


##############################
####    DAM variables     ####
##############################

variable "dam_version" {
  description = "The DAM version to install"
  type        = string
  default     = "14.11.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "license_file" {
  type        = string
  description = "License file"
}

variable "large_scale_mode" {
  type        = bool
  description = "DAM large scale mode"
  default     = true
}

variable "agent_count" {
  type        = number
  default     = 1
  description = "The agent sources to provision. Each with a database and a monitoring agent"
}


##############################
####    sonar variables   ####
##############################

variable "sonar_version" {
  type        = string
  default     = "4.11"
  description = "The Sonar version to install. Supported versions are: ['4.11']"
  validation {
    condition     = var.sonar_version == "4.11"
    error_message = "This example supports Sonar version 4.11"
  }
}

variable "hub_hadr" {
  type        = bool
  default     = true
  description = "Provisions a High Availability and Disaster Recovery node for the DSF Hub"
}

variable "agentless_gw_hadr" {
  type        = bool
  default     = true
  description = "Provisions a High Availability and Disaster Recovery node for the Agentless Gateway"
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
  description = "DSF Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 75
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
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

variable "database_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing dummy database access"
}


##############################
####    sonar variables   ####
##############################

variable "dra_version" {
  description = "The DRA version to install"
  type        = string
  default     = "4.12.0.10.0.6"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){5}\\d{1,2}$", var.dra_version))
    error_message = "Version must be in the format dd.dd.dd.dd.dd.dd where each dd is a number between 1-99 (e.g 4.12.0.10.0.6)"
  }
}

variable "dra_admin_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Admin Server compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 260
    volume_type = "gp3"
  }
}

variable "dra_analytics_group_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Analytics Server compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 1010
    volume_type = "gp3"
  }
}
