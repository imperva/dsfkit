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
  description = "Subnet id for the DSF MX instance"
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
  description = "key pair for DSF MX instance"
}

variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh and internal protocols to the DSF MX instance"
  default     = []
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh protocols to the DSF MX instance"
  default     = []
}

variable "sg_web_console_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing web console access to the DSF MX instance"
  default     = []
}

# variable "ami" {
#   type        = string
#   description = "Aws machine image"
# }

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF MX. Keep empty if you wish to create a new role."
}

variable "imperva_password" {
  type        = string
  description = "MX password"
  sensitive   = true
  validation {
    # Check that the password is at least 8 characters long
    condition     = length(var.imperva_password) >= 7 && length(var.imperva_password) <= 14
    error_message = "Password must be 7-14 characters long"
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
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.imperva_password))
    error_message = "Password must contain at least one of the following special character - *+=#%^:/~.,[]_"
  }
}

variable "secure_password" {
  type        = string
  description = "secure password (password between agent-gw -> mx)"
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

variable "license_file" {
  type        = string
  description = "DAM license file path. Make sure this license is valid before deploying DAM"
  validation {
    condition     = fileexists(var.license_file)
    error_message = "No such file on disk (${var.license_file})"
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