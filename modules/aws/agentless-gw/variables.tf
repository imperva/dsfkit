variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-agentless-gw"
  description = "Friendly name, EC2 Instace Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF agentless gw instance"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
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
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF agentless gw"
}

variable "ebs" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
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

variable "attach_public_ip" {
  type        = bool
  default     = true
  description = "Create public elastic IP for the instance"
}

variable "use_public_ip" {
  type        = bool
  default     = false
  description = "Setup sonar to be initialized with it's public IP. Mustn't be True if attach_public_ip is set to False"
}

variable "ingress_communication" {
  type = object({
    full_access_cidr_list = list(any) # will be attached to the following ports - 22, 8080, 8443, 3030, 27117
  })
  description = "List of allowed ingress cidr patterns for the Agentless gateway instance for ssh and internal protocols"
  nullable    = false
  validation {
    condition = alltrue([
      for address in var.ingress_communication.full_access_cidr_list : can(cidrnetmask(address))
    ]) && (length(var.ingress_communication.full_access_cidr_list) > 0)
    error_message = "Each item of the 'full_access_cidr_list' must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "binaries_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 DSF installation location"
  nullable    = false
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
    error_message = "Admin password must be at least 8 characters" # todo explain why we have here admin console
  }
  nullable = false
}

variable "ami" {
  type = object({
    id               = string
    name             = string
    username         = string
    owner_account_id = string
  })
  description = "Aws machine image filter details. Set to null if you wish to use the recommended image. The latest image that answers to this filter is chosen. Set owner_account_id to null to get the current account. username is the ami username (mandatory)."
  default     = null

  validation {
    condition     = var.ami == null || try(var.ami.id != null || var.ami.name != null, false)
    error_message = "ami id or name mustn't be null"
  }

  validation {
    condition     = var.ami == null || try(var.ami.username != null, false)
    error_message = "ami username mustn't be null"
  }
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF Gateway. Keep empty if you wish to create a new role."
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF agentless GW instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder can not be an empty string"
  }
}