variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

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
  default     = "imperva-dsf-hub"
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

variable "allowed_agentless_gw_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing DSF Agentless Gateways to access the DSF hub instance"
  validation {
    condition     = alltrue([for item in var.allowed_agentless_gw_cidrs : can(cidrnetmask(item))])
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
  description = "List of ingress CIDR patterns allowing other hubs access (hadr & health)"
  validation {
    condition     = alltrue([for item in var.allowed_hub_cidrs : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_dra_admin_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing access to DRA admin instances"
  validation {
    condition     = alltrue([for item in var.allowed_dra_admin_cidrs : can(cidrnetmask(item))])
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

variable "instance_type" {
  type        = string
  default     = "Standard_E8_v5" # 8 cores & 64GB ram
  description = "instance type for the DSF hub"
}

variable "storage_details" {
  type = object({
    disk_size            = number
    disk_iops_read_write = number
    storage_account_type = string
  })
  description = "Compute instance volume attributes"
}

variable "ingress_communication_via_proxy" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })
  description = "Proxy address used for ssh for private hub, Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
  default     = null
}

variable "attach_persistent_public_ip" {
  type        = bool
  default     = false
  description = "Create public elastic IP for the instance"
}

variable "use_public_ip" {
  type        = bool
  default     = false
  description = "Whether to use the DSF instance's public or private IP to check the instance's health"
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
  description = "Public key of the sonarw user taken from the main Hub output. This variable must only be defined for the DR Hub."
  default     = null
}

variable "main_node_sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the main Hub output. This variable must only be defined for the DR Hub."
  default     = null
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Initial password for all users"
  validation {
    condition     = var.password == null || try(length(var.password) > 8, false)
    error_message = "Must be at least 8 characters. Used only if 'password_secret_name' is not set."
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

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended."
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF hub instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}

variable "sonarw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the DSF Hub sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_public_key_content" {
  type        = string
  default     = null
  description = "The DSF Hub sonarw user public key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "generate_access_tokens" {
  type        = bool
  default     = false
  description = "Automatically generate access tokens for connecting to USC / connect DAM to the DSF Hub"
}

variable "mx_details" {
  description = "List of the DSF MX to onboard to USC"
  type = list(object({
    name     = string
    address  = string
    username = string
    password = string
  }))
  validation {
    condition = alltrue([
      for mx in var.mx_details : try(mx.address != null && mx.address != null, false)
    ])
    error_message = "Each MX must specify name and address"
  }
  validation {
    condition = alltrue([
      for mx in var.mx_details : try(mx.username != null && mx.password != null, false)
    ])
    error_message = "Each MX must specify username and password"
  }
  default = []
}

