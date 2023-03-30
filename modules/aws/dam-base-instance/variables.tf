variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DAM DSF instance"
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
  description = "key pair for DSF DAM instance"
}

variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh and internal protocols to the DSF DAM instance"
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns allowing ssh protocols to the DSF DAM instance"
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
    error_message = "Allowed values for DSF node type: \"mx\", \"agent-gw\""
  }
  nullable = false
}

variable "ses_model" {
  type        = string
  description = "Enter the Gateway/Mx Model"
  validation {
    condition     = contains(["AV2500", "AV6500", "AVM150"], var.ses_model)
    error_message = <<EOF
     Allowed values for DSF node type: "AV2500", "AV6500", "AVM150"
EOF
  }
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

variable "instance_initialization_completion_params" {
  description = "This variable allows the user to configure how to checks the health of the DAM instance after it is launched. Set enable to false to skip the verification, or true to perform the verification. Skipping is not recommended"
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

variable "ports" {
  description = "Ports needed for internal communication"
  type = object({
    tcp = list(string)
    udp = list(string)
  })
}

variable "iam_actions" {
  description = "Required AWS IAM action list for the DSF DAM instance"
  type        = list(string)
}