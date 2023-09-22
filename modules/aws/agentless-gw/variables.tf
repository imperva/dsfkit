variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
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
  description = "Subnet id for the Agentless Gateway instance"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
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

variable "instance_type" { # https://docs.imperva.com/bundle/z-kb-articles-km/page/a6defd0e.html
  type        = string
  default     = "r6i.xlarge" # 4 cores & 32GB ram
  description = "Ec2 instance type for the Agentless Gateway"
}

variable "ebs" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Compute instance volume attributes"
}

variable "gw_proxy_info" {
  type = object({
    ip_address           = string
    private_ssh_key_path = string
    ssh_user             = string
  })

  description = "Proxy address, private key file path and user used for ssh to a private Agentless Gateway. Keep empty if a proxy is not used."
  default = {
    ip_address           = null
    private_ssh_key_path = null
    ssh_user             = null
  }
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

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Password for admin user."
  validation {
    condition     = var.admin_password == null || try(length(var.admin_password) > 8, false)
    error_message = "Must be at least 8 characters."
  }
}

variable "admin_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the admin user password. If not set, 'password' is used."
}

variable "secadmin_password" {
  type        = string
  sensitive   = true
  description = "Password for secadmin user."
  validation {
    condition     = var.secadmin_password == null || try(length(var.secadmin_password) > 8, false)
    error_message = "Must be at least 8 characters."
  }
}

variable "secadmin_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the secadmin user password. If not set, 'password' is used."
}

variable "sonarg_password" {
  type        = string
  sensitive   = true
  description = "Password for sonarg user."
  validation {
    condition     = var.sonarg_password == null || try(length(var.sonarg_password) > 8, false)
    error_message = "Must be at least 8 characters."
  }
}

variable "sonarg_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the sonarg user password. If not set, 'password' is used."
}

variable "sonargd_password" {
  type        = string
  sensitive   = true
  description = "Password for sonargd user"
  validation {
    condition     = var.sonargd_password == null || try(length(var.sonargd_password) > 8, false)
    error_message = "Must be at least 8 characters."
  }
}

variable "sonargd_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the sonargd user password. If not set, 'password' is used."
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "ami" {
  type = object({
    id               = string
    name             = string
    username         = string
    owner_account_id = string
  })
  description = <<EOF
This variable is used for selecting an AWS machine image based on various filters. It is an object type variable that includes the following fields: id, name, username, and owner_account_id.
If set to null, the recommended image will be used.
The "id" and "name" fields are used to filter the machine image by ID or name, respectively. To select all available images for a given filter, set the relevant field to "*". The "username" field is mandatory and used to specify the AMI username.
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the current account ID will be used. The latest image that matches the specified filter will be chosen.
EOF
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
  description = "Secret name in AWS secrets manager which holds the Agentless Gateway sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_public_key_content" {
  type        = string
  default     = null
  description = "The Agentless Gateway sonarw user public key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "volume_attachment_device_name" {
  type        = string
  default     = null
  description = "The device name to expose to the instance for the ebs volume. Keep null if you have no preference"
}
