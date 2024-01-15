variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "resource_group" {
  type        = string
  description = "Azure existing resource group. Keep empty if you wish to create a new resource group"
  default     = null
}

variable "resource_group_location" {
  type        = string
  description = "In case var.resource_group is not provided and a new resource group is created, the new resource group will be created in this location (e.g 'East US'). The resource group location can be different from the Blob location defined via 'tarball_location' variable)"
  default     = null
}

variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources."
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
  description = "DSF Hub and MX web console IPs range. Specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the subnet (x.x.x.0/24) of the public IP of the computer where the Terraform is run is used Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "vnet_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Vnet ip range"
}

#variable "subnet_ids" {
#  type = object({
#    hub_subnet_id             = string
#    hub_dr_subnet_id          = string
#    agentless_gw_subnet_id    = string
#    agentless_gw_dr_subnet_id = string
#  })
#  default     = null
#  description = "The IDs of existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
#  validation {
#    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_subnet_id != null && var.subnet_ids.hub_dr_subnet_id != null && var.subnet_ids.agentless_gw_subnet_id != null && var.subnet_ids.agentless_gw_dr_subnet_id != null, false)
#    error_message = "Value must either be null or specified for all."
#  }
#  validation {
#    condition     = var.subnet_ids == null || try(alltrue([for subnet_id in values({ for k, v in var.subnet_ids : k => v if k != "db_subnet_ids" }) : can(regex(".*Microsoft.Network/virtualNetworks/.*/subnets/.*", subnet_id))]), false)
#    error_message = "Subnet id is invalid."
#  }
#}


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
  description = "License file path"
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

variable "dam_agent_installation_location" {
  type = object({
    az_resource_group  = string
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Storage account and container location of the DSF DAM agent installation software. az_blob is the full path to the installation file within the storage account container"
}

variable "simulation_db_types_for_agent" {
  type        = list(string)
  default     = ["MySql"]
  description = "Types of databases to provision on Azure VM with an Agent for simulation purposes. Available types are: 'PostgreSql' and 'MySql'. Note: agents won't be created for clusterless dam deployments (Less than 2 Agent Gateways)"
  validation {
    condition = alltrue([
      for db_type in var.simulation_db_types_for_agent : contains(["PostgreSql", "MySql"], db_type)
    ])
    error_message = "Value must be a subset of: ['PostgreSql', 'MySql']"
  }
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
    az_resource_group  = string
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Storage account and container location of the DSF installation software. az_blob is the full path to the tarball file within the storage account container"
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
  default     = "Standard_E4s_v5"
  description = "Instance type for the DSF Hub"
}

variable "agentless_gw_instance_type" {
  type        = string
  default     = "Standard_E4s_v5"
  description = "Instance type for the Agentless Gateway"
}

variable "hub_storage_details" {
  type = object({
    disk_size            = number
    disk_iops_read_write = number
    storage_account_type = string
  })
  default = {
    disk_size            = 250
    disk_iops_read_write = null
    storage_account_type = "Standard_LRS"
  }
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
}

variable "agentless_gw_storage_details" {
  type = object({
    disk_size            = number
    disk_iops_read_write = number
    storage_account_type = string
  })
  default = {
    disk_size            = 150
    disk_iops_read_write = null
    storage_account_type = "Standard_LRS"
  }
  description = "DSF Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "sonar_machine_base_directory" {
  type        = string
  default     = "/imperva"
  description = "The base directory where all Sonar related directories will be installed"
}