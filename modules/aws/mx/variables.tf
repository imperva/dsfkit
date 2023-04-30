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
  description = "Subnet id for the DSF MX instance"
  validation {
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

# variable "ec2_instance_type" {
#   type        = string
#   description = "Ec2 instance type for the DSF base instance"
#   default     = "m4.xlarge" # remove this default
# }

variable "attach_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
  default     = false
}

variable "key_pair" {
  type        = string
  description = "Key pair for the DSF MX instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids for the MX instance"
  default     = []
}

variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh and internal protocols to the DSF MX instance. This list should represent the agent gateways that are allowed to access the DSF MX instance via SSH and internal protocols"
  default     = []
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the DSF MX instance"
  default     = []
}

variable "sg_web_console_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing web console access to the DSF MX instance"
  default     = []
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF MX. Keep empty if you wish to create a new role."
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

variable "license_file" {
  type        = string
  description = "DAM license file path. Make sure this license is valid before deploying DAM otherwise this will result in an invalid deployment and loss of time"
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
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "large_scale_mode" {
  type        = bool
  description = "Large scale mode"
  default     = false
}

variable "create_service_group" {
  type        = bool
  description = "Create initial configuration to allow automatic agent on-boarding"
  default     = false
}

variable "dra_configuration" {
  type = object({
    address         = string
    port            = number
    username        = string
    password        = string
    remoteDirectory = string
  })
  default = null
}
