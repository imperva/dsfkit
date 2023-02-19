variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-hub"
  description = "Friendly name, vm instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF hub instance"
}

variable "security_group_id" {
  type        = string
  default     = null
  description = "Security group id for the DSF Hub instance. In case it is not set, a security group will be created automatically."
}

variable "instance_type" {
  type        = string
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "instance type for the DSF hub"
}

variable "storage_details" {
  type = object({
    storage_account_type = string
    disk_iops_read_write = number
    disk_size            = number
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
  default = {
    proxy_address              = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user             = null
  }
}

variable "create_and_attach_public_elastic_ip" {
  type        = bool
  default     = true
  description = "Create public elastic IP for the instance"
}

variable "ingress_communication" {
  type = object({
    full_access_cidr_list                   = list(any) #22, 8080, 8443, 3030, 27117
    additional_web_console_access_cidr_list = list(any) #8443
    use_public_ip                           = bool
  })
  description = "List of allowed ingress cidr patterns for the DSF agentless gw instance for ssh and internal protocols"
  nullable    = false
}

variable "ssh_key" {
  type = object({
    ssh_public_key            = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "binaries_location" {
  type = object({
    az_storage_account = string
    az_container       = string
    az_blob            = string
  })
  description = "Azure DSF installation location"
  nullable    = false
}

variable "hadr_secondary_node" {
  type        = bool
  default     = false
  description = "Is this a secondary HADR node"
}

variable "sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the primary Hub output. This variable must only be defined for the secondary Hub."
  default     = null
}

variable "sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the primary Hub output. This variable must only be defined for the secondary Hub."
  default     = null
}

variable "web_console_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
  validation {
    condition     = length(var.web_console_admin_password) > 8
    error_message = "Admin password must be at least 8 characters"
  }
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

#variable "role_arn" {
#  type        = string
#  default     = null
#  description = "IAM role to assign to DSF hub. Keep empty if you wish to create a new role."
#}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}
