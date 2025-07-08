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

variable "vnet_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Vnet ip range"
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "The ID of an existing subnet to put all resources in. Either 'subnet_id' or 'subnet_ids' should be provided but not both."
}

variable "subnet_ids" {
  type = object({
    hub_subnet_id             = string
    hub_dr_subnet_id          = string
    agentless_gw_subnet_id    = string
    agentless_gw_dr_subnet_id = string
    mx_subnet_id              = string
    db_subnet_ids             = list(string)
    agent_gw_subnet_id        = string
    dra_admin_subnet_id       = string
    dra_analytics_subnet_id   = string
  })
  default     = null
  description = "The IDs of existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets, or if you are providing the subnet_id variable. db_subnet_ids can be an empty list only if no databases should be provisioned."
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_subnet_id != null && var.subnet_ids.hub_dr_subnet_id != null && var.subnet_ids.agentless_gw_subnet_id != null && var.subnet_ids.agentless_gw_dr_subnet_id != null && var.subnet_ids.dra_admin_subnet_id != null && var.subnet_ids.dra_analytics_subnet_id != null, false)
    error_message = "Value must either be null or specified for all."
  }
}

##############################
####    DAM variables     ####
##############################

variable "dam_version" {
  type        = string
  description = "The DAM version to install"
  default     = "14.17.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,3}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "dam_license" {
  description = "License file path"
  type        = string
  default     = null
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
  default     = null
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
  default     = "4.19"
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
  description = "Storage account and container location of the DSF Sonar installation software. az_blob is the full path to the tarball file within the storage account container"
  default     = {
    az_resource_group  = ""
    az_storage_account = ""
    az_container       = ""
    az_blob            = ""
  }
}

variable "tarball_url" {
  type        = string
  default     = ""
  description = "HTTPS DSF installation location. If not set, binaries_location is used"
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

variable "hub_instance_size" {
  type        = string
  default     = "Standard_E8s_v5"
  description = "Instance size for the DSF Hub"
}

variable "agentless_gw_instance_size" {
  type        = string
  default     = "Standard_E4s_v5"
  description = "Instance size for the Agentless Gateway"
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

variable "simulation_db_types_for_agentless" {
  type        = list(string)
  default     = ["MsSQL"]
  description = "Types of databases to provision and onboard to an Agentless Gateway for simulation purposes. Available types are: 'MsSQL'."
  validation {
    condition = alltrue([
      for db_type in var.simulation_db_types_for_agentless : contains(["MsSQL"], db_type)
    ])
    error_message = "Value must be a subset of: ['MsSQL']"
  }
}

##############################
####    DRA variables     ####
##############################

variable "dra_admin_instance_size" {
  type        = string
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "VM instance size for the Admin Server"
}

variable "dra_admin_storage_details" {
  type = object({
    disk_size            = number
    volume_caching       = string
    storage_account_type = string
  })
  description = "DRA Admin compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    disk_size            = 260
    volume_caching       = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

variable "dra_admin_image_details" {
  type = object({
    resource_group_name = string
    image_id            = string
  })
  default     = null
  description = "Image attributes for the Admin Server"
  validation {
    condition     = var.dra_admin_image_details == null || try(var.dra_admin_image_details.resource_group_name != null && var.dra_admin_image_details.image_id != null, false)
    error_message = "Value must either be null or specified for all"
  }
}

variable "dra_admin_vhd_details" {
  type = object({
    path_to_vhd          = string
    storage_account_name = string
    container_name       = string
  })
  default     = null
  description = "VHD details for creating the Admin server image. 'path_to_vhd' is the name of the VHD within the container, for example 'DRA-x.x.x.x.x.x_x86_64-Admin.vhd'. Keep empty if you provide an image for the Admin server instead."
  validation {
    condition     = var.dra_admin_vhd_details == null || try(var.dra_admin_vhd_details.path_to_vhd != null && var.dra_admin_vhd_details.storage_account_name != null && var.dra_admin_vhd_details.container_name != null, false)
    error_message = "Value must either be null or specified for all"
  }
}

variable "dra_analytics_instance_size" {
  type        = string
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "VM instance size for the Analytics Server"
}

variable "dra_analytics_storage_details" {
  type = object({
    disk_size            = number
    volume_caching       = string
    storage_account_type = string
  })
  description = "DRA Analytics compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    disk_size            = 1010
    volume_caching       = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

variable "dra_analytics_image_details" {
  type = object({
    resource_group_name = string
    image_id            = string
  })
  default     = null
  description = "Image attributes for the Analytics Server"
  validation {
    condition     = var.dra_analytics_image_details == null || try(var.dra_analytics_image_details.resource_group_name != null && var.dra_analytics_image_details.image_id != null, false)
    error_message = "Value must either be null or specified for all"
  }
}

variable "dra_analytics_vhd_details" {
  type = object({
    path_to_vhd          = string
    storage_account_name = string
    container_name       = string
  })
  default     = null
  description = "VHD details for creating the Analytics server image. 'path_to_vhd' is the name of the VHD within the container, for example 'DRA-x.x.x.x.x.x_x86_64-Analytics.vhd'. Keep empty if you provide an image for the Analytics server instead."
  validation {
    condition     = var.dra_analytics_vhd_details == null || try(var.dra_analytics_vhd_details.path_to_vhd != null && var.dra_analytics_vhd_details.storage_account_name != null && var.dra_analytics_vhd_details.container_name != null, false)
    error_message = "Value must either be null or specified for all"
  }
}
