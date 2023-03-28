variable "name" {
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

# variable "ebs_details" {
#   type = object({
#     disk_size        = number
#     provisioned_iops = number
#     throughput       = number
#   })
#   description = "Compute instance volume attributes"
# }

variable "attach_public_ip" {
  type        = bool
  description = "Create public IP for the instance"
}

# variable "use_public_ip" {
#   type        = bool
#   description = "Create public IP for the instance"
# }

variable "key_pair" {
  type        = string
  description = "key pair for DSF base instance"
}

variable "web_console_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the DSF instance for web console"
  default     = []
}

variable "sg_ingress_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the DSF instance for ssh and internal protocols"
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

variable "resource_type" {
  type = string
  validation {
    condition     = contains(["mx", "agent-gw"], var.resource_type)
    error_message = "Allowed values for DSF node type: \"mx\", \"agent-gw\""
  }
  nullable = false
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Admin password"
  validation {
    condition     = length(var.password) > 8
    error_message = "Admin password must be at least 8 characters"
  }
  nullable = false
}

# variable "ssh_key_path" {
#   type        = string
#   description = "SSH key path"
#   nullable    = false
# }

# variable "proxy_info" {
#   type = object({
#     proxy_address      = string
#     proxy_ssh_key_path = string
#     proxy_ssh_user     = string
#   })
#   description = "Proxy address, private key file path and user used for ssh to a private DSF node. Keep empty if a proxy is not used."
#   default = {
#     proxy_address      = null
#     proxy_ssh_key_path = null
#     proxy_ssh_user     = null
#   }
# }

# variable "skip_instance_health_verification" {
#   description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
# }

# variable "terraform_script_path_folder" {
#   type        = string
#   description = "Terraform script path folder to create terraform temporary script files on a sonar base instance. Use '.' to represent the instance home directory"
#   default     = null
#   validation {
#     condition     = var.terraform_script_path_folder != ""
#     error_message = "Terraform script path folder can not be an empty string"
#   }
# }

variable "license_file" {
}
