variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-dra-admin"
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

variable "instance_type" {
  type        = string
  default     = "m4.xlarge"
  description = "EC2 instance type for the Admin Server"
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "ami" {
  type = object({
    id               = string
    name             = string
    owner_account_id = string
  })
  description = <<EOF
This variable is used for selecting an AWS machine image based on various filters. It is an object type variable that includes the following fields: id, name and owner_account_id.
The "id" and "name" fields are used to filter the machine image by ID or name, respectively. To select all available images for a given filter, set the relevant field to "*".
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the default owner will be Imperva AWS account id.
The latest image that matches the specified filter will be chosen.
EOF

  validation {
    condition     = var.ami != null && (var.ami.id != null || var.ami.name != null)
    error_message = "Either the 'id' or the 'name' should be specified"
  }
}

variable "admin_analytics_registration_password" {
  type = string
  description = "Password to be used to register Analytics Server to Admin Server"
}

variable "subnet_id" {
  type = string
  description = "Subnet id for the Admin Server"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids to attach to the Admin Server instance"
  validation {
    condition = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default     = []
}

variable "allowed_analytics_server_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing the Analytics Server to access the DSF Admin Server instance"
  validation {
    condition = alltrue([for item in var.allowed_analytics_server_cidrs : can(cidrnetmask(item))])
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

variable "allowed_web_console_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing web console access"
  validation {
    condition = alltrue([for item in var.allowed_web_console_cidrs : can(cidrnetmask(item))])
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

variable "attach_persistent_public_ip" {
  type        = bool
  default     = false
  description = "Create and attach elastic public IP for the instance"
}

variable "ebs" {
  type = object({
    volume_size      = number
    volume_type      = string
  })
  description = "Compute instance volume attributes for the Admin Server"
  default = {
    volume_size      = 260
    volume_type      = "gp3"
  }
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DRA Admin. Keep empty if you wish to create a new role."
}
