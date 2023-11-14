variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF base instance"
  validation {
    condition     = can(regex(".*Microsoft.Network/virtualNetworks/.*/subnets/.*", var.subnet_id))
    error_message = "The variable must match the pattern 'Microsoft.Network/virtualNetworks/<virtualNetworkName>/subnets/<subnetName>'"
  }
}

variable "resource_type" {
  type = string
  validation {
    condition     = contains(["hub", "agentless-gw"], var.resource_type)
    error_message = "Allowed values for DSF node type: \"hub\", \"agentless-gw\""
  }
  nullable = false
}

variable "security_groups_config" {
  description = "Security groups config"
  type = list(object({
    name            = list(string)
    internet_access = bool
    udp             = list(number)
    tcp             = list(number)
    cidrs           = list(string)
  }))
}

variable "security_group_ids" {
  type        = list(string)
  description = "security group ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    condition     = length(var.security_group_ids) == 0 || length(var.security_group_ids) == 1
    error_message = "Can't contain more than a single element"
  }
  default = []
}

variable "attach_persistent_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
}

variable "public_ssh_key" {
  type        = string
  description = "Key for the DSF base instance"
}

variable "use_public_ip" {
  type        = bool
  description = "Whether to use the DSF instance's public or private IP to check the instance's health"
}

variable "storage_details" {
  type = object({
    disk_size            = number
    disk_iops_read_write = number
    storage_account_type = string
  })
  description = "Compute instance external volume attributes"
  validation {
    condition     = var.storage_details.disk_size >= 150
    error_message = "Disk size must be at least 150 GB"
  }
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "This variable is used for selecting an Azure machine image. If set to null, the recommended image will be used."
  default     = null
}

variable "vm_user" {
  type        = string
  default     = null
  description = "VM user to use for SSH. Keep empty to use the default user."
}

variable "instance_type" {
  type        = string
  description = "vm type for the DSF base instance"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for all users"
  validation {
    condition     = var.password == null || try(length(var.password) >= 7, false)
    error_message = "Must be at least 7 characters. Used only if 'password_secret_name' is not set."
  }
}


variable "ssh_key_path" {
  type        = string
  description = "SSH key path"
  nullable    = false
}

variable "additional_install_parameters" {
  default = ""
}

variable "binaries_location" {
  type = object({
    az_resource_group  = string
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Azure DSF installation location"
  nullable    = false
}

variable "hadr_dr_node" {
  type        = bool
  default     = false
  description = "Is this node an HADR DR one"
}

variable "main_node_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the main node output. This variable must only be defined for the DR node."
  default     = null
}

variable "main_node_sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the main node output. This variable must only be defined for the DR node."
  default     = null
}

variable "proxy_info" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })
  description = "Proxy address, private key file path and user used for ssh to a private DSF node. Keep empty if a proxy is not used."
  default     = null
}

variable "hub_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the main Hub output. This variable must only be defined for the Gateway. Used, for example, in federation."
  default     = null
}

variable "skip_instance_health_verification" {
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended."
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on a sonar base instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}

variable "sonarw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the DSF node sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_public_key_content" {
  type        = string
  default     = null
  description = "The DSF node sonarw user public key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "generate_access_tokens" {
  type        = bool
  default     = false
  description = "Generate access tokens for connecting to USC / connect DAM to the DSF Hub"
}

variable "send_usage_statistics" {
  type        = bool
  description = "Set to true to send usage statistics."
}
