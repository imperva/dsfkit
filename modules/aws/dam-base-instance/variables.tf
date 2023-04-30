variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF DAM instance"
  validation {
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids for the ec2 instance"
  default     = []
}

# variable "ec2_instance_type" {
#   type        = string
#   description = "Ec2 instance type for the DSF base instance"
#   default     = "m4.xlarge" # remove this default
# }

variable "attach_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
}

variable "key_pair" {
  type        = string
  description = "Key pair for the DSF DAM instance"
}

variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh and internal protocols to the DSF DAM instance"
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the DSF DAM instance"
}

# variable "ami" {
#   type        = string
#   description = "Aws machine image"
# }

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF DAM instance. Keep empty if you wish to create a new role."
}

variable "resource_type" {
  type = string
  validation {
    condition     = contains(["mx", "agent-gw"], var.resource_type)
    error_message = "Allowed values for DSF DAM node type: \"mx\", \"agent-gw\""
  }
  nullable = false
}

variable "dam_model" {
  type        = string
  description = "Enter the Agent Gateway/MX Model"
  validation {
    condition     = contains(["AV2500", "AV6500", "AVM150"], var.dam_model)
    error_message = <<EOF
     Allowed values for DSF DAM node type: "AV2500", "AV6500", "AVM150"
EOF
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

variable "instance_readiness_params" {
  description = "This variable allows the user to configure how to check the readiness and health of the DAM instance after it is launched. Set enable to false to skip the verification, or true to perform the verification. Skipping is not recommended"
  type = object({
    enable   = bool
    commands = string
    timeout  = number
    }
  )
}

variable "user_data_commands" {
  type        = list(string)
  description = "Commands that run on instance startup. Should contain at least the FTL command"
}

variable "internal_ports" {
  description = "Ports needed for internal communication"
  type = object({
    tcp = list(string)
    udp = list(string)
  })
}

variable "dam_version" {
  description = "The DAM version to install"
  type        = string
  default     = "14.11.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "iam_actions" {
  description = "Required AWS IAM action list for the DSF DAM instance"
  type        = list(string)
}