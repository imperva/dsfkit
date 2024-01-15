variable "name" {
  type        = string
  default     = "imperva-dsf-dra-admin"
  description = "Friendly name to identify all resources"
  validation {
    condition     = length(var.name) >= 3
    error_message = "Friendly name must be at least 3 characters"
  }
  validation {
    condition     = can(regex("^\\p{L}.*", var.name))
    error_message = "Must start with a letter"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "instance_size" {
  type        = string
# maybe we can use a smaller vm size - requirements - Admin Server: 16 GB RAM, 4 CPU cores and 260 GB of hard drive space
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "VM instance size for the Admin Server"
}

variable "ssh_public_key" {
  type = string
  description = "SSH public key to access machine"
  nullable = false
}

variable "image_details" {
  type = object({
    resource_group_name  = string
    image_id        = string
  })
  description = "Image attributes for the Admin Server"
  nullable    = false
}

#variable "dra_version" {
#  type        = string
#  default     = "4.13"
#  description = "The DRA version to install. Supported versions are 4.11.0.10.0.7 and up. Both long and short version formats are supported, for example, 4.11.0.10.0.7 or 4.11. The short format maps to the latest patch."
#  nullable    = false
#  validation {
#    condition     = !startswith(var.dra_version, "4.10.") && !startswith(var.dra_version, "4.9.") && !startswith(var.dra_version, "4.8.") && !startswith(var.dra_version, "4.3.") && !startswith(var.dra_version, "4.2.") && !startswith(var.dra_version, "4.1.")
#    error_message = "The dra_version value must be 4.11.0.10 or higher"
#  }
#}

variable "vm_user" {
  type        = string
  default     = "cbadmin"
  description = "VM user to use for SSH. Keep empty to use the default user."
}

variable "admin_registration_password" {
  type        = string
  description = "Password to be used to register Analytics Server to Admin Server"

  validation {
    condition     = length(var.admin_registration_password) >= 7
    error_message = "Password must be at least 7 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.admin_registration_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.admin_registration_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.admin_registration_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.admin_registration_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
  }
}

variable "admin_password" {
  type        = string
  description = "Password to be used to admin os user"

  validation {
    condition     = length(var.admin_password) >= 7
    error_message = "Password must be at least 7 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.admin_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.admin_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.admin_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.admin_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the Admin Server"
  validation {
    condition     = can(regex(".*Microsoft.Network/virtualNetworks/.*/subnets/.*", var.subnet_id))
    error_message = "The variable must match the pattern 'Microsoft.Network/virtualNetworks/<virtualNetworkName>/subnets/<subnetName>'"
  }
}

# todo - handle - who use it?
variable "security_group_ids" {
  type        = list(string)
  description = "Security group Ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    # validate if true
    condition     = length(var.security_group_ids) == 0 || length(var.security_group_ids) == 1
    error_message = "Can't contain more than a single element"
  }
  validation {
    condition     = alltrue([for item in var.security_group_ids : can(regex(".*Microsoft.Network/networkSecurityGroups/.*", item))])
    error_message = "One or more of the security group ids list is invalid. Each item should match the pattern '.*Microsoft.Network/networkSecurityGroups/<network-security-group-name>"
  }
#  validation {
#    condition     = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
#    error_message = "One or more of the security group Ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
#  }
  default = []
}

variable "allowed_analytics_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing the Analytics Server to access the DSF Admin Server instance"
  validation {
    condition     = alltrue([for item in var.allowed_analytics_cidrs : can(cidrnetmask(item))])
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

variable "allowed_web_console_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing web console access"
  validation {
    condition     = alltrue([for item in var.allowed_web_console_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_hub_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing hub access"
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

variable "attach_persistent_public_ip" {
  type        = bool
  default     = true
  description = "Create and attach an Elastic public IP for the instance. If false, a dynamic public IP is used. Relevant only if the DRA Admin is in a public subnet (ignored if in a private subnet). Currently, due to a DRA limitation, must only be true."
}

variable "storage_details" {
  type = object({
    disk_size            = number
    disk_iops_read_write = number
    storage_account_type = string
  })
  description = "Compute instance volume attributes for the Admin Server"
  default = {
    disk_size = 260
    disk_iops_read_write = null
    storage_account_type = "Standard_LRS"
  }
}

variable "send_usage_statistics" {
  type        = bool
  default     = true
  description = "Set to true to send usage statistics."
}
