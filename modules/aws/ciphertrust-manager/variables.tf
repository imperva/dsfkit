variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
  default     = "imperva-dsf-ciphertrust-manager"
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
  description = "Subnet id for the CipherTrust Manager instances"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "security_group_ids" {
  type        = list(string)
  description = "AWS security group Ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    condition     = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group Ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default = []
}

variable "allowed_web_console_and_api_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing web console and api access"
  validation {
    condition     = alltrue([for item in var.allowed_web_console_and_api_cidrs : can(cidrnetmask(item))])
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

variable "allowed_cluster_nodes_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing other CipherTrust Manager cluster nodes to access the CipherTrust Manager instance"
  validation {
    condition     = alltrue([for item in var.allowed_cluster_nodes_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_cte_agents_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing CTE agents to access the CipherTrust Manager instance"
  validation {
    condition     = alltrue([for item in var.allowed_cte_agents_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_ddc_agents_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing DDC agents to access the CipherTrust Manager instance"
  validation {
    condition     = alltrue([for item in var.allowed_ddc_agents_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_all_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing all types of access: ssh, API, web console, etc."
  validation {
    condition     = alltrue([for item in var.allowed_all_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "instance_type" {
  type        = string
  default     = "t2.xlarge"
  description = "EC2 instance type for the CipherTrust Manager"
}

variable "ebs" {
  type = object({
    volume_size = number
    volume_type = string
    iops        = number
  })
  description = "Compute instance volume attributes for the CipherTrust Manager"
}

variable "attach_persistent_public_ip" {
  type        = bool
  default     = false
  description = "Create public elastic IP for the instance"
}

variable "key_pair" {
  type        = string
  description = "Key pair for the CipherTrust Manager instance"
}

variable "ssh_user" {
  type    = string
  default = "ksadmin"
}

variable "ciphertrust_manager_version" {
  type        = string
  default     = "2.20"
  description = "The CipherTrust Manager version to install"
  validation {
    condition     = can(regex("^\\d{1,2}\\.\\d{1,3}$", var.ciphertrust_manager_version))
    error_message = "Version must be in the format dd.dd where each dd is a number between 1-99 (e.g 2.20)"
  }
  validation {
    condition     = split(".", var.ciphertrust_manager_version)[0] == "2"
    error_message = "CipherTrust Manager version not supported."
  }
}

variable "ami" {
  type = object({
    id               = string
    name_regex       = string
    product_code     = string
    owner_account_id = string
  })
  description = <<EOF
This variable shouldn't be used unless you know you should use it. It allows you to pick a none official CipherTrust Manager release (not from market place).
Keep empty if you prefer to use the ciphertrust_manager_version variable.
This variable is used for selecting an AWS machine image based on various filters. It is an object type variable that includes the following fields: id, name_regex, product_code, and owner_account_id.
If set to null, the recommended image will be used.
The "id" and "name_regex" fields are used to filter the machine image by ID or name regex, respectively.
The "name_regex" field is used to filter the machine name regex. To select all available images for a given filter, set the relevant field to "*" (name_regex should be set to ".*").
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the current account ID will be used. The latest image that matches the specified filter will be chosen.
EOF
  default     = null

  validation {
    condition     = var.ami == null || try(var.ami.id != null || var.ami.name_regex != null, false)
    error_message = "ami id or name_regex mustn't be null"
  }
}
