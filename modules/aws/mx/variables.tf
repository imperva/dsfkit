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
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "ebs" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Compute instance volume attributes for the MX"
  default = {
    volume_size = 160
    volume_type = "gp2"
  }
}

variable "instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the instance. Keep empty if you wish to create a new IAM role and profile"
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

variable "allowed_agent_gw_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing Agent Gateways to access the DSF MX instance"
  validation {
    condition     = alltrue([for item in var.allowed_agent_gw_cidrs : can(cidrnetmask(item))])
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

variable "allowed_web_console_and_api_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing web console access"
  validation {
    condition     = alltrue([for item in var.allowed_web_console_and_api_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_hub_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing DSF Hub access"
  validation {
    condition     = alltrue([for item in var.allowed_hub_cidrs : can(cidrnetmask(item))])
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

variable "key_pair" {
  type        = string
  description = "Key pair for the DSF MX instance"
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
    condition     = can(regex("[*+#%^:/~.,\\[\\]_]", var.secure_password))
    error_message = "Password must contain at least one of the following special characters: *+=#%^:/~.,[]_"
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
  type        = string
  description = "The DAM version to install"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)."
  }
  validation {
    condition     = split(".", var.dam_version)[0] == "14"
    error_message = "DAM version not supported."
  }
}

variable "ami" {
  type = object({
    id               = string
    name             = string
    owner_account_id = string
  })
  description = <<EOF
This variable shouldn't be used unless you know you should use it. It allows you to pick a none official DAM release (not from market place).
It is used for selecting an AWS machine image based on various filters.
It is an object type variable that includes the following fields: id, name and owner_account_id.
The "id" and "name" fields are used to filter the machine image by ID or name, respectively. To select all available images for a given filter, set the relevant field to "*".
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the current account ID will be used. The latest image that matches the specified filter will be chosen.
EOF
  default     = null

  validation {
    condition     = var.ami == null || try(var.ami.id != null || var.ami.name != null, false)
    error_message = "ami id or name mustn't be null"
  }
}

variable "large_scale_mode" {
  type        = bool
  description = "Large scale mode"
  default     = false
}

variable "license" {
  description = <<EOF
  License information. Must be one of the following:
  1. Activation code (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  2. License file path
  EOF
  type        = string
  validation {
    condition     = fileexists(var.license) || can(regex("^[[:alnum:]]{8}-([[:alnum:]]{4}-){3}[[:alnum:]]{12}$", var.license))
    error_message = "Invalid license file (No such file on disk). Can either be an activation code in the format of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx or a path to a license file on disk"
  }
  validation {
    condition     = !fileexists(var.license) || can(regex(".*AV[2,6]500.*", file(var.license)))
    error_message = "License is invalid. It must allow AWS DAM models (AV2500/AV6500). More info in https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf"
  }
}

variable "attach_persistent_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
  default     = false
}


variable "create_server_group" {
  type        = bool
  description = "Create initial configuration to allow automatic agent on-boarding"
  default     = false
}

variable "dra_details" {
  description = "Details of the DRA for sending audit logs in the legacy format. More info in https://docs.imperva.com/bundle/v4.14-data-risk-analytics-installation-guide/page/60553.htm"
  type = object({
    address         = string
    port            = number
    username        = string
    password        = string
    remoteDirectory = string
  })
  default = null
}

variable "hub_details" {
  description = "Details of the DSF hub for sending audit logs"
  type = object({
    address      = string
    port         = number
    access_token = string
  })
  default = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "send_usage_statistics" {
  type        = bool
  default     = true
  description = "Set to true to send usage statistics."
}
