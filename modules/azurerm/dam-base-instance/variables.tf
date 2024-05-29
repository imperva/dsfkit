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

variable "storage_details" {
  type = object({
    disk_size            = number
    storage_account_type = string
  })
  description = "Compute instance volume attributes for the DAM base instance"
}

variable "vm_user" {
  type        = string
  description = "VM user."
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "This variable is used for selecting an Azure DAM machine image. If set to null, the image will be determine according to dam_version variable."
  default     = null
}

variable "instance_readiness_params" {
  description = "This variable allows the user to configure how to check the readiness and health of the DAM instance after it is launched. Set enable to false to skip the verification, or true to perform the verification. Skipping is not recommended."
  type = object({
    enable   = bool
    commands = string
    timeout  = number
  })
}

variable "custom_scripts" {
  type        = map(string)
  description = "A map of custom scripts to run on the Azure DAM machine, which associates a unique script key with its content. Should contain at least the FTL command with 'ftl' script key"
}

variable "dam_version" {
  type        = string
  description = "The DAM version to install"
  nullable    = false
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,3}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "resource_type" {
  type = string
  validation {
    condition     = contains(["mx", "agent-gw"], var.resource_type)
    error_message = "Allowed values for DSF node type: \"mx\", \"agent-gw\""
  }
  nullable = false
}

variable "dam_model" {
  type        = string
  description = "Enter the Agent Gateway/MX Model. More info in https://www.imperva.com/resources/datasheets/Imperva_VirtualAppliances_V2.3_20220518.pdf"
  validation {
    condition     = contains(["MV2500", "MV6500", "MVM150"], var.dam_model)
    error_message = <<EOF
     Allowed values for DSF DAM node type: "MV2500", "MV6500", "MVM150"
EOF
  }
}

variable "send_usage_statistics" {
  type        = bool
  description = "Set to true to send usage statistics."
}

