variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
  description = "Resource group details"
}

variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-agentless-gw"
  description = "Friendly name, vm instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF agentless gw instance"
  # validation {
  #   condition     = length(var.subnet_id) >= 15 && regex("/subnets/", var.subnet_id)
  #   error_message = "Subnet id is invalid. Must contain '/subnets/'"
  # }
}

variable "security_group_id" {
  type        = string
  default     = null
  description = "Security group id for the Agentless GW instance. In case it is not set, a security group will be created automatically."
  validation {
    condition     = var.security_group_id == null ? true : (substr(var.security_group_id, 0, 3) == "sg-")
    error_message = "Security group id is invalid. Must be sg-********"
  }
}

variable "public_ip" {
  type        = bool
  default     = false
  description = "Create public IP for the instance"
}

variable "instance_type" {
  type        = string
  default     = "Standard_E4as_v5" # 4 cores & 32GB ram
  description = "Ec2 instance type for the DSF agentless gw"
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
  description = "Proxy address used for ssh for private gw (Usually hub address), Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
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
    full_access_cidr_list = list(any) #22, 8080, 8443, 3030, 27117
    use_public_ip         = bool
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
  description = "Is this node a HADR secondary one"
}

variable "hub_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the primary Hub output"
  nullable    = false
}

variable "sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the primary Gateway output. This variable must only be defined for the secondary Gateway."
  default     = null
}

variable "sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the primary Gateway output. This variable must only be defined for the secondary Gateway."
  default     = null
}

variable "web_console_admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
  validation {
    condition     = length(var.web_console_admin_password) > 8
    error_message = "Admin password must be at least 8 characters" # tbd explain why we have here admin console
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
#  description = "IAM role to assign to DSF gw. Keep empty if you wish to create a new role."
#}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}