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
  default     = "imperva-dsf-agentless-gw"
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

variable "allowed_hub_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing hub to access the Agentless Gateway instance"
  validation {
    condition     = alltrue([for item in var.allowed_hub_cidrs : can(cidrnetmask(item))])
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

variable "allowed_agentless_gw_cidrs" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing other Agentless Gateways access (hadr)"
  validation {
    condition     = alltrue([for item in var.allowed_agentless_gw_cidrs : can(cidrnetmask(item))])
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

variable "public_ip" {
  type        = bool
  default     = false
  description = "Create public IP for the instance"
}

variable "instance_type" {
  type        = string
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "Ec2 instance type for the Agentless Gateway"
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
  description = "Proxy address used for ssh for private Agentless Gateway (Usually hub address), Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
  default     = null
}

variable "binaries_location" {
  type = object({
    az_resource_group  = string
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Azure DSF installation location. If tarball_url not set, binaries_location is used"
  default = {
    az_resource_group  = ""
    az_storage_account = ""
    az_container       = ""
    az_blob            = ""
  }
}

variable "tarball_url" {
  type        = string
  default     = ""
  description = "HTTPS DSF installation location. If not set, binaries_location is used"
}

variable "hadr_dr_node" {
  type        = bool
  default     = false
  description = "Is this node an HADR DR one"
}

variable "hub_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the main Hub output"
  nullable    = false
}

variable "main_node_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the main Agentless Gateway output. This variable must only be defined for the DR Agentless Gateway."
  default     = null
}

variable "main_node_sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the main Agentless Gateway output. This variable must only be defined for the DR Agentless Gateway."
  default     = null
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Initial password for all users"
  validation {
    condition     = var.password == null || try(length(var.password) >= 7, false)
    error_message = "Must be at least 7 characters. Used only if 'password_secret_name' is not set."
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
  default     = null
  description = "VM image details to base image for the compute instance"
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
  description = "Terraform script path folder to create terraform temporary script files on the Agentless Gateway instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}

variable "sonarw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the Agentless Gateway sonarw user SSH private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_public_key_content" {
  type        = string
  default     = null
  description = "The Agentless Gateway sonarw user SSH public key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "send_usage_statistics" {
  type        = bool
  default     = true
  description = "Set to true to send usage statistics."
}
