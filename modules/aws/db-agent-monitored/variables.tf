variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
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
  description = "Subnet id for the DSF MX instance"
  validation {
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

# variable "username" {
#   type        = string
#   description = "Master username must contain 1–16 alphanumeric characters, the first character must be a letter, and name can not be a word reserved by the database engine."
#   default     = "admin"
#   validation {
#     condition     = length(var.username) > 1
#     error_message = "Master username name must be at least 1 characters"
#   }
# }

# variable "password" {
#   type        = string
#   description = "Master password must contain 8–41 printable ASCII characters, and can not contain /, \", @, or a space."
#   default     = ""
#   validation {
#     condition     = length(var.password) == 0 || length(var.password) > 7
#     error_message = "Master password name must be at least 8 characters"
#   }
# }


variable "mx_password" {
  type        = string
  description = "Password for MX api"
}

variable "secure_password" {
  type        = string
  description = "Password for agent registration"
}

variable "management_server_host_for_api_access" {
  type        = string
  description = "Management server's hostname or IP address. It is utilized to access the API"
  validation {
    condition     = var.management_server_host_for_api_access == null || can(regex("[^0-9.]", var.management_server_host_for_api_access)) || cidrsubnet("${var.management_server_host_for_api_access}/32", 0, 0) == "${var.management_server_host_for_api_access}/32"
    error_message = "Invalid IPv4 address"
  }
}

variable "agent_gateway_host" {
  type        = string
  description = "Agent gateway hostname or IP address. It is used for agent registration"
  validation {
    condition     = var.agent_gateway_host == null || can(regex("[^0-9.]", var.agent_gateway_host)) || cidrsubnet("${var.agent_gateway_host}/32", 0, 0) == "${var.agent_gateway_host}/32"
    error_message = "Invalid IPv4 address"
  }
}

variable "key_pair" {
  type        = string
  description = "Key pair for the ec2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids for the ec2 instance"
  default     = []
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the ec2 instance"
  default     = []
}
