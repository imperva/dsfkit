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
  default     = "imperva-dsf-mx"
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

variable "storage_details" {
  type = object({
    disk_size            = number
    storage_account_type = string
  })
  description = "Compute instance volume attributes for the MX"
  default = {
    disk_size            = 160
    storage_account_type = "Standard_LRS"
  }
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

variable "allowed_agent_gw_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing Agent Gateways to access the DSF MX instance"
  validation {
    condition     = alltrue([for item in var.allowed_agent_gw_cidrs : can(cidrnetmask(item))])
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

variable "allowed_web_console_and_api_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing web console access"
  validation {
    condition     = alltrue([for item in var.allowed_web_console_and_api_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_hub_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing DSF Hub access"
  validation {
    condition     = alltrue([for item in var.allowed_hub_cidrs : can(cidrnetmask(item))])
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

variable "ssh_key" {
  type = object({
    ssh_public_key            = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "mx_password" {
  type        = string
  description = "MX password. This password will also serve as a secure password, namely for the purpose of for communication between the Management Server and the Agent Gateway."
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
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)."
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

variable "license" {
  description = "License file path"
  type        = string
  validation {
    condition     = fileexists(var.license)
    error_message = "Invalid license file (No such file on disk)"
  }
  validation {
    condition     = !fileexists(var.license) || can(regex(".*MV[2,6]500.*", file(var.license)))
    error_message = "License is invalid. It must allow DAM models (MV2500/MV6500). More info in https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf"
  }
}

variable "attach_persistent_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
  default     = false
}

variable "create_server_group" {
  type        = bool
  description = "Create initial configuration to allow automatic agent on-boarding"
  default     = false
}

variable "hub_details" {
  description = "Details of the DSF hub for sending audit logs"
  type = object({
    address      = string
    port         = number
    access_token = string
  })
  default = null
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
