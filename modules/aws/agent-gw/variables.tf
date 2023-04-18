variable "friendly_name" {
  type        = string
  description = "Friendly name to identify to all resources"
  validation {
    condition     = length(var.friendly_name) >= 3
    error_message = "Variable must be at least 3 characters long"
  }
  validation {
    condition     = can(regex("^\\p{L}.*", var.friendly_name))
    error_message = "Variable must start with a letter"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF Agent GW instance"
  validation {
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

# variable "security_group_id" {
#   type        = string
#   description = "Security group id for the ec2 instance"
# }

# variable "ec2_instance_type" {
#   type        = string
#   description = "Ec2 instance type for the DSF base instance"
#   default     = "m4.xlarge" # remove this default
# }

variable "key_pair" {
  type        = string
  description = "key pair for DSF Agent GW"
}

}
variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh and internal protocols to the DSF Agent GW instance"
  default     = []
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh protocols to the DSF Agent GW instance"
  default     = []
}

variable "sg_agent_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing agent traffic to the DSF Agent GW instance"
  default     = []
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF Agent GW. Keep empty if you wish to create a new role."
}

variable "mx_password" {
  type        = string
  description = "MX password"
  sensitive   = true
  validation {
    # Check that the password is at least 8 characters long
    condition     = length(var.mx_password) >= 7 && length(var.mx_password) <= 14
    error_message = "Password must be 7-14 characters long"
  }

  validation {
    # Check that the password contains at least one uppercase letter
    condition     = can(regex("[A-Z]", var.mx_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    # Check that the password contains at least one lowercase letter
    condition     = can(regex("[a-z]", var.mx_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    # Check that the password contains at least one digit
    condition     = can(regex("\\d", var.mx_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    # Check that the password contains at least one special character
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.mx_password))
    error_message = "Password must contain at least one of the following special character - *+=#%^:/~.,[]_"
  }
}

variable "secure_password" {
  type        = string
  description = "The password used for communication between the Management Server and the Gateway"
  sensitive   = true
  validation {
    # Check that the password is at least 8 characters long
    condition     = length(var.secure_password) >= 7 && length(var.secure_password) <= 14
    error_message = "Password must be 7-14 characters long"
  }

  validation {
    # Check that the password contains at least one uppercase letter
    condition     = can(regex("[A-Z]", var.secure_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    # Check that the password contains at least one lowercase letter
    condition     = can(regex("[a-z]", var.secure_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    # Check that the password contains at least one digit
    condition     = can(regex("\\d", var.secure_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    # Check that the password contains at least one special character
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.secure_password))
    error_message = "Password must contain at least one of the following special character - *+=#%^:/~.,[]_"
  }
}

variable "agent_listener_port" {
  type        = number
  description = "Enter listener\"s port number."
  default     = 8030
  validation {
    # Check that the port number is within the relevant range of TCP ports (0-65535)
    condition     = var.agent_listener_port >= 0 && var.agent_listener_port <= 65535
    error_message = "Port number must be within the range of 0-65535"
  }
}

variable "agent_listener_ssl" {
  type        = bool
  description = "This option may increase CPU consumption on the Agent host. Do you wish to enable SSL?"
  default     = false
}

variable "management_server_host" {
  type        = string
  description = "Enter Management Server\"s Hostname or IP address"
  validation {
    condition     = can(regex("[^0-9.]", var.management_server_host)) || cidrsubnet("${var.management_server_host}/32", 0, 0) == "${var.management_server_host}/32"
    error_message = "Invalid IPv4 address"
  }
}

variable "gw_model" {
  type        = string
  description = "Enter the Gateway Model"
  default     = "AV2500"
  validation {
    condition     = contains(["AV2500", "AV6500"], var.gw_model)
    error_message = <<EOF
     Allowed values for DSF Agent GW: "AV2500", "AV6500"
EOF
  }
}


variable "group_id" {
  type        = string
  description = "Gw group id. Keep empty to get random id"
  default     = null
  validation {
    condition     = var.group_id == null || try(length(var.group_id) >= 3, false)
    error_message = "Id must be at least 3 chrachters long"
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
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99"
  }
}