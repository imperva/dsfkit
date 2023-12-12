variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "enable_sonar" {
  type        = bool
  default     = true
  description = "Provision DSF Hub and Agentless Gateways (formerly Sonar). To provision only a DSF Hub, set agentless_gw_count to 0."
}

variable "enable_dam" {
  type        = bool
  default     = true
  description = "Provision DAM MX and Agent Gateways"
}

variable "enable_dra" {
  type        = bool
  default     = true
  description = "Provision DRA Admin and Analytics"
}

variable "agentless_gw_count" {
  type        = number
  default     = 1
  description = "Number of Agentless Gateways. Provisioning Agentless Gateways requires the enable_sonar variable to be set to 'true'."
}

variable "agent_gw_count" {
  type        = number
  default     = 2 # Minimum count for a cluster
  description = "Number of Agent Gateways. Provisioning Agent Gateways requires the enable_dam variable to be set to 'true'."
}

variable "dra_analytics_count" {
  type        = number
  default     = 1
  description = "Number of DRA Analytics servers. Provisioning Analytics servers requires the enable_dra variable to be set to 'true'."
}

variable "password" {
  sensitive   = true
  type        = string
  default     = null # Random
  description = "Password for all users and components including internal communication (DRA instances, Agent and Agentless Gateways, MX and Hub) and also to MX and DSF Hub web console (Randomly generated if not set)"
}

##############################
#### networking variables ####
##############################
variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub, MX and DRA Admin web consoles IPs range. Specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the subnet (x.x.x.0/24) of the public IP of the computer where the Terraform is run is used. Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "IP ranges from which SSH access to the deployed DSF nodes will be allowed"
  default     = []
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
    hub_subnet_id             = string
    hub_dr_subnet_id          = string
    agentless_gw_subnet_id    = string
    agentless_gw_dr_subnet_id = string
    mx_subnet_id              = string
    agent_gw_subnet_id        = string
    dra_admin_subnet_id       = string
    dra_analytics_subnet_id   = string
    db_subnet_ids             = list(string)
  })
  default     = null
  description = "The IDs of existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_subnet_id != null && var.subnet_ids.hub_dr_subnet_id != null && var.subnet_ids.agentless_gw_subnet_id != null && var.subnet_ids.agentless_gw_dr_subnet_id != null && var.subnet_ids.mx_subnet_id != null && var.subnet_ids.agent_gw_subnet_id != null && var.subnet_ids.dra_admin_subnet_id != null && var.subnet_ids.dra_analytics_subnet_id != null && var.subnet_ids.db_subnet_ids != null, false)
    error_message = "Value must either be null or specified for all"
  }
  validation {
    condition     = var.subnet_ids == null || try(alltrue([for subnet_id in values({ for k, v in var.subnet_ids : k => v if k != "db_subnet_ids" }) : length(subnet_id) >= 15 && substr(subnet_id, 0, 7) == "subnet-"]), false)
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

##############################
####    DAM variables     ####
##############################

variable "dam_version" {
  type        = string
  description = "The DAM version to install"
  default     = "14.13.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "dam_license" {
  description = <<EOF
  DAM license information. Must be one of the following:
  1. Activation code (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  2. License file path (Make sure it allows AWS DAM models (AV2500/AV6500))
  EOF
  type        = string
}

variable "large_scale_mode" {
  type = object({
    mx       = bool
    agent_gw = bool
  })
  description = "DAM large scale mode"
  validation {
    condition     = var.large_scale_mode.mx == false || var.large_scale_mode.agent_gw == true
    error_message = "MX large scale mode requires setting large scale mode in the Agentless Gateway as well"
  }
  default = {
    mx       = false
    agent_gw = false
  }
}

variable "mx_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "MX compute instance volume attributes"
  default = {
    volume_size = 160
    volume_type = "gp2"
  }
}

variable "agent_gw_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Agent Gateway compute instance volume attributes"
  default = {
    volume_size = 160
    volume_type = "gp2"
  }
}

variable "simulation_db_types_for_agent" {
  type        = list(string)
  default     = ["MySql"]
  description = "Types of databases to provision on EC2 with an Agent for simulation purposes. Available types are: 'PostgreSql', 'MySql' and 'MariaDB'. Note: agents won't be created for clusterless dam deployments (Less than 2 Agent Gateways)"
  validation {
    condition = alltrue([
      for db_type in var.simulation_db_types_for_agent : contains(["PostgreSql", "MySql", "MariaDB"], db_type)
    ])
    error_message = "Value must be a subset of: ['PostgreSql', 'MySql', 'MariaDB']"
  }
}

variable "agent_source_os" {
  type        = string
  default     = "Ubuntu"
  description = "Agent OS type"
}

##############################
####    Sonar variables   ####
##############################

variable "sonar_version" {
  type        = string
  default     = "4.13"
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  validation {
    condition     = !startswith(var.sonar_version, "4.9.") && !startswith(var.sonar_version, "4.10.")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}
variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket location of the DSF installation software. s3_key is the full path to the tarball file within the bucket, for example, 'prefix/jsonar-x.y.z.w.u.tar.gz'"
  default     = null
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

variable "hub_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF Hub"
}

variable "agentless_gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the Agentless Gateway"
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

variable "agentless_gw_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "simulation_db_types_for_agentless" {
  type        = list(string)
  default     = ["RDS MsSQL"]
  description = "Types of databases to provision and onboard to an Agentless Gateway for simulation purposes. Available types are: 'RDS MySQL' and 'RDS MsSQL'. 'RDS MsSQL' includes simulation data."
  validation {
    condition = alltrue([
      for db_type in var.simulation_db_types_for_agentless : contains(["RDS MySQL", "RDS MsSQL"], db_type)
    ])
    error_message = "Value must be a subset of: ['RDS MySQL', 'RDS MsSQL']"
  }
}

variable "database_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing dummy database access"
}

##############################
####    DRA variables     ####
##############################

variable "dra_version" {
  type        = string
  default     = "4.13"
  description = "The DRA version to install. Supported versions are 4.11.0.10 and up. Both long and short version formats are supported, for example, 4.11.0.10 or 4.11. The short format maps to the latest patch."
  validation {
    condition     = !startswith(var.dra_version, "4.10.") && !startswith(var.dra_version, "4.9.") && !startswith(var.dra_version, "4.8.") && !startswith(var.dra_version, "4.3.") && !startswith(var.dra_version, "4.2.") && !startswith(var.dra_version, "4.1.")
    error_message = "The dra_version value must be 4.11.0.10 or higher"
  }
}

variable "dra_admin_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "DRA Admin compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 260
    volume_type = "gp3"
  }
}

variable "dra_analytics_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "DRA Analytics compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 1010
    volume_type = "gp3"
  }
}
