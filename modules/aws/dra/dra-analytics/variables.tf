variable "friendly_name" {
    type = string
    description = "friendly_name"
}

variable "admin_analytics_registration_password_arn" {
    type = string
    description = "Password to be used to register Analytics Server to Admin Server"
}

variable "archiver_user" {
    type = string
    description = "User to be used to upload archive files for the Analysis Server"
}
variable "analytics_ami_id" {
    type = string
    description = "DRA analytics AMI ID in region"
    # default = "ami-06c0b1409371fd42f"
}

variable "admin_server_private_ip" {
    type = string
    description = "admin_server_private_ip"
}

variable "admin_server_public_ip" {
    type = string
    description = "admin_server_public_ip"
}

variable "instance_type" {
    type = string
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"
  nullable = false
}

variable "archiver_password" {
    type = string
    description = "Password to be used to upload archive files for analysis"
}

variable "vpc_security_group_ids" {
    type = list(string)
    description = "vpc_security_group_ids"
    default     = null
}

variable "subnet_id" {
    type = string
    description = "subnet_id"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids to attach to the Analytics Server instance"
  validation {
    condition = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default     = []
}

variable "allowed_admin_server_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing the Admin Server to access the DSF Admin Server instance"
  validation {
    condition = alltrue([for item in var.allowed_admin_server_cidrs : can(cidrnetmask(item))])
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

variable "allowed_all_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing access to all relevant protocols (E.g vpc cidr range)"
  validation {
    condition = alltrue([for item in var.allowed_all_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default     = []
}

variable "ebs" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Compute instance volume attributes"
  default = null
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the Analytics Server. Keep empty if you wish to create a new role."
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}
