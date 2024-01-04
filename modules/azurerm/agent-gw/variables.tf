variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
  default     = "imperva-dsf-agent-gw"
  validation {
    condition     = length(var.friendly_name) >= 3
    error_message = "Must be at least 3 characters long"
  }
  validation {
    condition     = can(regex("^\\p{L}.*", var.friendly_name))
    error_message = "Must start with a letter"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF base instance"
  validation {
    condition     = can(regex(".*Microsoft.Network/virtualNetworks/.*/subnets/.*", var.subnet_id))
    error_message = "The variable must match the pattern 'Microsoft.Network/virtualNetworks/<virtualNetworkName>/subnets/<subnetName>'"
  }
}

variable "ssh_key" {
  type = object({
    ssh_public_key            = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    condition     = length(var.security_group_ids) == 0 || length(var.security_group_ids) == 1
    error_message = "Can't contain more than a single element"
  }
  validation {
    condition     = alltrue([for item in var.security_group_ids : can(regex(".*Microsoft.Network/networkSecurityGroups/.*", item))])
    error_message = "One or more of the security group ids list is invalid. Each item should match the pattern '.*Microsoft.Network/networkSecurityGroups/<network-security-group-name>"
  }
  default = []
}

variable "allowed_mx_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing mx to access the DSF Agent Gateway instance"
  validation {
    condition     = alltrue([for item in var.allowed_mx_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing ssh access"
  validation {
    condition     = alltrue([for item in var.allowed_ssh_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_agent_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing agents to access the DSF Agent Gateway instance"
  validation {
    condition     = alltrue([for item in var.allowed_agent_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_gw_clusters_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing other members of a DSF Agent Gateway cluster to approach this instance"
  validation {
    condition     = alltrue([for item in var.allowed_gw_clusters_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_all_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing access to all relevant protocols (E.g vpc cidr range)"
  validation {
    condition     = alltrue([for item in var.allowed_all_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "storage_details" {
  type = object({
    disk_size            = number
    storage_account_type = string
  })
  description = "Compute instance volume attributes for the MX"
  default = {
    disk_size = 160
    storage_account_type = "Standard_LRS"
  }
}

variable "mx_password" {
  type        = string
  description = "MX password"
  sensitive   = true
  validation {
    condition     = length(var.mx_password) >= 7 && length(var.mx_password) <= 14
    error_message = "Password must be 7-14 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.mx_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.mx_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.mx_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[_]", var.mx_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[_"
  }
}

variable "timezone" {
  type    = string
  default = "UTC"
}

variable "vm_user" {
  type        = string
  default     = "adminuser"
  description = "VM user. Keep empty to use the default user."
}

variable "dam_version" {
  type        = string
  description = "The DAM version to install"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
  validation {
    condition     = split(".", var.dam_version)[0] == "14"
    error_message = "DAM version not supported."
  }
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "This variable is used for selecting an Azure DAM machine image. If set to null, the image will be determine according to dam_version variable."
  default     = null
}

variable "large_scale_mode" {
  type        = bool
  description = "Large scale mode"
  default     = false
}

variable "agent_listener_port" {
  type        = number
  description = "Enter listener's port number."
  default     = 8030
  validation {
    condition     = var.agent_listener_port >= 0 && var.agent_listener_port <= 65535
    error_message = "Port number must be within the range of 0-65535"
  }
}

variable "agent_listener_ssl" {
  type        = bool
  description = "Use SSL encrypted data tunnels (May increase CPU consumption on the Agent host)."
  default     = false
}

variable "management_server_host_for_registration" {
  type        = string
  description = "Management server's hostname or IP address. Used for registering the Agent Gateway."
  validation {
    condition     = can(regex("[^0-9.]", var.management_server_host_for_registration)) || cidrsubnet("${var.management_server_host_for_registration}/32", 0, 0) == "${var.management_server_host_for_registration}/32"
    error_message = "Invalid IPv4 address"
  }
}

variable "management_server_host_for_api_access" {
  type        = string
  description = "Management server's hostname or IP address. It is utilized to access the API and ensure that the Agent Gateway is operational and ready. Leave empty if you wish to use the same value from management_server_host_for_registration variable."
  validation {
    condition     = var.management_server_host_for_api_access == null || can(regex("[^0-9.]", var.management_server_host_for_api_access)) || cidrsubnet("${var.management_server_host_for_api_access}/32", 0, 0) == "${var.management_server_host_for_api_access}/32"
    error_message = "Invalid IPv4 address"
  }
  default = null
}

variable "gw_model" {
  type        = string
  description = "DSF Agent Gateway model"
  default     = "MV2500"
  validation {
    condition     = contains(["MV2500", "MV6500"], var.gw_model)
    error_message = <<EOF
     Allowed values for DSF Agent Gateway: "MV2500", "MV6500". More info in https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf
EOF
  }
}

variable "gateway_group_name" {
  type        = string
  description = "The name of the Agent Gateway Group in which to provision the Agent Gateway. Keep empty to get a random name. It is not possible to provision Agent Gateway directly in a Cluster, to achieve this, provision the Agent Gateway in a Gateway Group and then move it to the Cluster."
  default     = null
  validation {
    condition     = var.gateway_group_name == null || try(length(var.gateway_group_name) >= 3, false)
    error_message = "The gateway group name must be at least 3 characters long"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "send_usage_statistics" {
  type        = bool
  default     = true
  description = "Set to true to send usage statistics."
}
