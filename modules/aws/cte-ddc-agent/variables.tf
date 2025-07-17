variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
  default     = "imperva-dsf-cte-ddc-agent"
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

variable "security_group_ids" {
  type        = list(string)
  description = "AWS security group Ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  validation {
    condition     = alltrue([for item in var.security_group_ids : substr(item, 0, 3) == "sg-"])
    error_message = "One or more of the security group Ids list is invalid. Each item should be in the format of 'sg-xx..xxx'"
  }
  default = []
}

variable "attach_persistent_public_ip" {
  type        = bool
  default     = false
  description = "Create and attach elastic public IP for the instance"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the ec2 instance"
  default     = []
}

variable "allowed_rdp_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing rdp protocols to the ec2 instance"
  default     = []
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "cipher_trust_manager_address" {
  type        = string
  description = "CipherTrust Manager address to register to"
  nullable    = false
}

variable "os_type" {
  type        = string
  description = "Os type to provision as EC2, available types are: ['Red Hat', 'Windows']"
  nullable    = false
  validation {
    condition     = var.os_type == null || try(contains(["Red Hat", "Windows"], var.os_type), false)
    error_message = "Valid values should contain at least one of the following: 'Red Hat', 'Windows']"
  }
}

variable "agent_installation" {
  type = object({
    registration_token          = string
    install_cte                 = bool
    install_ddc                 = bool
    cte_agent_installation_file = string
    ddc_agent_installation_file = string
  })
  description = "Agent installation files to use for the agent installation and registration token for the CTE agent. The files should be accessible from the machine where Terraform is running."
  nullable    = false
  validation {
    condition     = var.agent_installation.install_cte || var.agent_installation.install_ddc
    error_message = "At least one of install_cte or install_ddc must be true"
  }
  validation {
    condition     = var.agent_installation.install_cte == false || var.agent_installation.cte_agent_installation_file != null
    error_message = "CTE agent installation file must be provided if install_cte is true"
  }
  validation {
    condition     = var.agent_installation.install_ddc == false || var.agent_installation.ddc_agent_installation_file != null
    error_message = "DDC agent installation file must be provided if install_ddc is true"
  }
  validation {
    condition     = var.agent_installation.cte_agent_installation_file == null || try(fileexists(var.agent_installation.cte_agent_installation_file), false)
    error_message = "CTE agent installation file does not exist at the specified path."
  }
  validation {
    condition     = var.agent_installation.ddc_agent_installation_file == null || try(fileexists(var.agent_installation.ddc_agent_installation_file), false)
    error_message = "DDC agent installation file does not exist at the specified path"
  }
}

variable "instance_type" {
  type        = string
  description = "Instance type to use for the agent instances"
  default     = "t2.large"
  nullable    = false
}

variable "use_public_ip" {
  type        = bool
  default     = false
  description = "Whether to use the agent instance's public or private IP for ssh access"
}

variable "ingress_communication_via_proxy" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })
  description = "Proxy address used for ssh for private CTE-DDC agent (Usually hub address), Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
  default     = null
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the CTE-DDC agent instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}