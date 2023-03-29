variable "friendly_name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the ec2 instance"
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
  description = "key pair for DSF base instance"
}

variable "web_console_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns for the DSF instance for web console"
  default     = []
}

variable "sg_ingress_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns for the DSF instance for ssh and internal protocols"
  default     = []
}

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress cidr patterns for the DSF instance for ssh"
}

# variable "ami" {
#   type        = string
#   description = "Aws machine image"
# }

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF node. Keep empty if you wish to create a new role."
}

variable "imperva_password" {
  type        = string
  description = "MX password"
  sensitive   = true
  validation {
    condition     = length(var.imperva_password) > 8
    error_message = "MX password must be at least 8 characters"
  }
  nullable = false
}

variable "secure_password" {
  type        = string
  description = "secure password (password between gw -> mx)"
  sensitive   = true
  validation {
    condition     = length(var.secure_password) > 8
    error_message = "secure password must be at least 8 characters"
  }
  nullable = false
}

variable "license_file" {
}

variable "timezone" {
  type    = string
  default = "UTC"
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}