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

variable "attach_public_ip" {
  type        = bool
  description = "Create public IP for the instance"
}

variable "key_pair" {
  type        = string
  description = "key pair for DSF Agent GW"
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

# variable "ami" {
#   type        = string
#   description = "Aws machine image"
# }

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF Agent GW. Keep empty if you wish to create a new role."
}

variable "imperva_password" {
  type        = string
  description = "MX password"
  sensitive   = true
  validation {
    # Check that the password is at least 8 characters long
    condition     = length(var.imperva_password) >= 8
    error_message = "Password must be at least 8 characters long"
  }

  validation {
    # Check that the password contains at least one uppercase letter
    condition     = can(regex("[A-Z]", var.imperva_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    # Check that the password contains at least one lowercase letter
    condition     = can(regex("[a-z]", var.imperva_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    # Check that the password contains at least one digit
    condition     = can(regex("\\d", var.imperva_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    # Check that the password contains at least one special character
    condition     = can(regex("[^a-zA-Z0-9]", var.imperva_password))
    error_message = "Password must contain at least one special character"
  }
}

variable "secure_password" {
  type        = string
  description = "secure password (password between agent-gw -> mx)"
  sensitive   = true
  validation {
    # Check that the password is at least 8 characters long
    condition     = length(var.secure_password) >= 8
    error_message = "Password must be at least 8 characters long"
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
    condition     = can(regex("[^a-zA-Z0-9]", var.secure_password))
    error_message = "Password must contain at least one special character"
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

variable "large_scale_mode" {
  type        = bool
  description = "Large scale mode"
  default     = false
}

variable "group_id" {
  type        = string
  description = "Gw group id"
  default     = null
}

variable "timezone" {
  type    = string
  default = "UTC"
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}
