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
  description = "Subnet id for the DSF Agent Gateway instance"
  validation {
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "key_pair" {
  type        = string
  description = "Key pair for the DSF Agent Gateway"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids to attach to the DSF Agent Gateway instance"
  validation {
    condition = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default     = []
}

variable "allowed_mx_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing mx to access the DSF Agent Gateway instance"
  validation {
    condition = alltrue([for item in var.allowed_mx_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing ssh access"
  validation {
    condition = alltrue([for item in var.allowed_ssh_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "allowed_agent_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing agents to access the DSF Agent Gateway instance"
  validation {
    condition = alltrue([for item in var.allowed_agent_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "allowed_gw_clusters_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing other members of a DSF Agent Gateway cluster to approach this instance"
  validation {
    condition = alltrue([for item in var.allowed_gw_clusters_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "allowed_all_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing access to all relevant protocols (E.g vpc cidr range)"
  validation {
    condition = alltrue([for item in var.allowed_all_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF Agent Gateway. Keep empty if you wish to create a new role"
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
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.mx_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
  }
}

variable "secure_password" {
  type        = string
  description = "The password used for communication between the Management Server and the Agent Gateway"
  sensitive   = true
  validation {
    condition     = length(var.secure_password) >= 7 && length(var.secure_password) <= 14
    error_message = "Password must be 7-14 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.secure_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.secure_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.secure_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.secure_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
  }
}

variable "timezone" {
  type    = string
  default = "UTC"
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}

variable "dam_version" {
  description = "DAM version"
  type        = string
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
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
  default     = "AV2500"
  validation {
    condition     = contains(["AV2500", "AV6500"], var.gw_model)
    error_message = <<EOF
     Allowed values for DSF Agent Gateway: "AV2500", "AV6500". More info in https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf
EOF
  }
}

variable "gateway_group_id" {
  type        = string
  description = "Gw group id (Keep empty to get random id)"
  default     = null
  validation {
    condition     = var.gateway_group_id == null || try(length(var.gateway_group_id) >= 3, false)
    error_message = "Id must be at least 3 chrachters long"
  }
}
