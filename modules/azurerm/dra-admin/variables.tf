variable "name" {
  type        = string
  default     = "imperva-dsf-dra-admin"
  description = "Friendly name to identify all resources"
  validation {
    condition     = length(var.name) >= 3
    error_message = "Name must be at least 3 characters"
  }
  validation {
    condition     = can(regex("^\\p{L}.*", var.name))
    error_message = "Name must start with a letter"
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
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "VM instance size for the Admin Server"
}

variable "ssh_public_key" {
  type = string
  description = "SSH public key to access machine"
  nullable = false
}

variable "image_vhd_details" {
  type = object({
    image = optional(object({
      resource_group_name = string
      image_id            = string
    }))
    vhd = optional(object({
      path_to_vhd          = string
      storage_account_name = string
      container_name       = string
    }))
  })
  description = "Image or VHD details for the Admin Server"
  default = null

  validation {
    condition     = try((var.image_vhd_details.image != null && var.image_vhd_details.vhd == null || (var.image_vhd_details.image == null && var.image_vhd_details.vhd != null)), false)
    error_message = "Either one of 'image' or 'vhd' should be specified but not both."
  }
  validation {
    condition     = var.image_vhd_details.image == null || try(var.image_vhd_details.image.resource_group_name != null && var.image_vhd_details.image.image_id != null, false)
    error_message = "Image value must either be null or specified for all"
  }
    validation {
      condition     = var.image_vhd_details.vhd == null || try(var.image_vhd_details.vhd.path_to_vhd != null && var.image_vhd_details.vhd.storage_account_name != null && var.image_vhd_details.vhd.container_name != null, false)
      error_message = "VHD value must either be null or specified for all"
    }
}

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

variable "admin_ssh_password" {
  type        = string
  description = "Password to be used to ssh to the Admin Server"

  validation {
    condition     = length(var.admin_ssh_password) >= 7
    error_message = "Password must be at least 7 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.admin_ssh_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.admin_ssh_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.admin_ssh_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.admin_ssh_password))
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
    volume_caching       = string
    storage_account_type = string
  })
  description = "Compute instance volume attributes for the Admin Server"
  default = {
    disk_size = 260
    volume_caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

variable "send_usage_statistics" {
  type        = bool
  default     = true
  description = "Set to true to send usage statistics."
}
