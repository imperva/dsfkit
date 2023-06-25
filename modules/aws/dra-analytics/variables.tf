variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-dra-analytics"
  description = "Friendly name, EC2 Instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
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

variable "admin_password" {
  type        = string
  description = "Password to be used to admin os user"

  validation {
    condition     = length(var.admin_password) >= 7
    error_message = "Password must be at least 7 characters long"
  }

  validation {
    condition     = can(regex("[A-Z]", var.admin_password))
    error_message = "Password must contain at least one uppercase letter"
  }

  validation {
    condition     = can(regex("[a-z]", var.admin_password))
    error_message = "Password must contain at least one lowercase letter"
  }

  validation {
    condition     = can(regex("\\d", var.admin_password))
    error_message = "Password must contain at least one digit"
  }

  validation {
    condition     = can(regex("[*+=#%^:/~.,\\[\\]_]", var.admin_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
  }
}

variable "archiver_user" {
  type        = string
  default     = "archiver-user"
  description = "User to be used to upload archive files for the analytics server"
}

variable "dra_version" {
  description = "The DRA version to install"
  type        = string
  default     = "4.11.0.20.0.21"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){5}\\d{1,2}$", var.dra_version))
    error_message = "Version must be in the format dd.dd.dd.dd.dd.dd where each dd is a number between 1-99 (e.g 4.12.0.10.0.6)"
  }
}

variable "admin_server_private_ip" {
  type        = string
  description = "Private IP of the Admin Server"
}

variable "admin_server_public_ip" {
  type        = string
  description = "Public IP of the Admin Server"
}

variable "instance_type" {
  type        = string
  default     = "m4.xlarge"
  description = "EC2 instance type for the Analytics Server"
}

variable "key_pair" {
  type        = string
  description = "key pair"
}

variable "archiver_password" {
  type        = string
  description = "Password to be used to upload archive files for analysis"
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the Analytics Server"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids to attach to the Analytics Server instance"
  validation {
    condition     = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default = []
}

variable "allowed_admin_server_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing the Admin Server to access the Analytics Server instance"
  validation {
    condition     = alltrue([for item in var.allowed_admin_server_cidrs : can(cidrnetmask(item))])
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

variable "allowed_gateways_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing agent and agentless gateway access"
  validation {
    condition     = alltrue([for item in var.allowed_gateways_cidrs : can(cidrnetmask(item))])
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

variable "ebs" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Compute instance volume attributes for the Analytics Server"
  default = {
    volume_size = 1010
    volume_type = "gp3"
  }
}

variable "instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the instance. Keep empty if you wish to create a new IAM role and profile"
}
