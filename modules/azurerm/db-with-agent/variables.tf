variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
  default     = "imperva-dsf-db-with-agent"

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
  description = "Subnet id for the DSF base instance"
  validation {
    condition     = can(regex(".*Microsoft.Network/virtualNetworks/.*/subnets/.*", var.subnet_id))
    error_message = "The variable must match the pattern 'Microsoft.Network/virtualNetworks/<virtualNetworkName>/subnets/<subnetName>'"
  }
}

variable "ssh_key" {
  type = object({
    ssh_public_key            = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "security_group_ids" {
  type        = list(string)
  description = "Security group ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    condition     = length(var.security_group_ids) == 0 || length(var.security_group_ids) == 1
    error_message = "Can't contain more than a single element"
  }
  validation {
    condition     = alltrue([for item in var.security_group_ids : can(regex(".*Microsoft.Network/networkSecurityGroups/.*", item))])
    error_message = "One or more of the security group ids list is invalid. Each item should match the pattern '.*Microsoft.Network/networkSecurityGroups/<network-security-group-name>"
  }
  default = []
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the VM instance"
  default     = []
}

variable "db_type" {
  type        = string
  default     = null
  description = "Types of databases to provision on VM with an Agent for simulation purposes. Available types are: 'PostgreSql' and 'MySql'. If not set, one DB type is randomly chosen."
  validation {
    condition     = var.db_type == null || try(contains(["PostgreSql", "MySql"], var.db_type), false)
    error_message = "Value must be a subset of: ['PostgreSql', 'MySql']"
  }
}

variable "registration_params" {
  type = object(
    {
      agent_gateway_host = string
      secure_password    = string
      site               = string
      server_group       = string
    }
  )
  description = "Registration parameters for DAM agent"
}

variable "binaries_location" {
  type = object({
    az_resource_group  = string
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Azure DSF DAM agent installation location"
  nullable    = false
}

variable "vm_instance_type" {
  type        = string
  description = "Instance type for the VM"
  default     = "Standard_B1s"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
