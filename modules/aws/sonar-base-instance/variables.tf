variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
}

variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF base instance"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
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
  description = "AWS security group Ids to attach to the instance. If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
  default     = []
}

variable "attach_persistent_public_ip" {
  type        = bool
  description = "Create and attach elastic public IP for the instance"
}

variable "key_pair" {
  type        = string
  description = "Key pair for the DSF base instance"
}

variable "instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the instance. Keep empty if you wish to create a new IAM role and profile"
}

variable "use_public_ip" {
  type        = bool
  description = "Whether to use the DSF instance's public or private IP to check the instance's health"
}

variable "ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Compute instance external volume attributes"
  validation {
    condition     = var.ebs_details.disk_size >= 150
    error_message = "Disk size must be at least 150 GB"
  }
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
  nullable    = true

  validation {
    condition     = var.ami == null || try(var.ami.id != null || var.ami.name != null, false)
    error_message = "ami id or name mustn't be null"
  }

  validation {
    condition     = var.ami == null || try(var.ami.username != null, false)
    error_message = "ami username mustn't be null"
  }
}

variable "ec2_instance_type" {
  type        = string
  description = "Ec2 instance type for the DSF base instance"
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
    ip_address           = string
    private_ssh_key_path = string
    ssh_user             = string
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

variable "volume_attachment_device_name" {
  type        = string
  default     = null
  description = "The device name to expose to the instance for the ebs volume. Keep null if you have no preference"
}