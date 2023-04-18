variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-hub"
  description = "Friendly name, EC2 Instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF hub instance"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "security_group_id" {
  type        = string
  default     = null
  description = "Security group id for the DSF Hub instance. In case it is not set, a security group will be created automatically."
  validation {
    condition     = var.security_group_id == null ? true : (substr(var.security_group_id, 0, 3) == "sg-")
    error_message = "Security group id is invalid. Must be sg-********"
  }
}

variable "instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "EC2 instance type for the DSF hub"
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
  description = "Proxy address used for ssh for private hub, Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
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
  description = "Whether to use the DSF instance's public or private IP to check the instance's health"
}

variable "ingress_communication" {
  type = object({
    full_access_cidr_list                   = list(any) # will be attached to sg.tf:ingress_ports
    additional_web_console_access_cidr_list = list(any) # will be attached to port 8443
  })
  description = "List of allowed ingress CIDR patterns for the DSF Hub instance for ssh and internal protocols"
  nullable    = false
  validation {
    condition = alltrue([
      for address in var.ingress_communication.full_access_cidr_list : can(cidrnetmask(address))
    ]) && (length(var.ingress_communication.full_access_cidr_list) > 0)
    error_message = "Each item of the 'full_access_cidr_list' must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  validation {
    condition = alltrue([
      for address in var.ingress_communication.additional_web_console_access_cidr_list : can(cidrnetmask(address))
    ]) && (length(var.ingress_communication.additional_web_console_access_cidr_list) > 0)
    error_message = "Each item of the 'additional_web_console_access_cidr_list' must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
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

variable "hadr_secondary_node" {
  type        = bool
  default     = false
  description = "Is this node an HADR secondary one"
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

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF Hub. Keep empty if you wish to create a new role."
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
  description = "Terraform script path folder to create terraform temporary script files on the DSF hub instance. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder can not be an empty string"
  }
}