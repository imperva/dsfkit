variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the ec2 instance"
}

variable "ec2_instance_type" {
  type        = string
  description = "Ec2 instance type for the DSF base instance"
}

variable "ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Compute instance volume attributes"
}

variable "create_and_attach_public_elastic_ip" {
  type        = bool
  description = "Create public IP for the instance"
}

variable "use_public_ip" {
  type        = bool
  description = "Create public IP for the instance"
}

variable "key_pair" {
  type        = string
  description = "key pair for DSF base instance. This key must be generated by the hub or gw module and present on the local disk."
}

variable "web_console_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the DSF instance for web console"
  default     = []
}

variable "sg_ingress_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the DSF instance for ssh and internal protocols"
}

variable "ami_name_tag" {
  type = string
}

variable "ami_user" {
  type        = string
  default     = null
  description = "Ami user to use for SSH to the EC2. Keep empty to use the default user."
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DSF node. Keep empty if you wish to create a new role."
}

variable "resource_type" {
  type = string
  validation {
    condition     = contains(["hub", "gw"], var.resource_type)
    error_message = "Allowed values for DSF node type: \"hub\", \"gw\""
  }
  nullable = false
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
    s3_key    = string
  })
  description = "S3 DSF installation location"
  nullable    = false
}

variable "hadr_secondary_node" {
  type        = bool
  default     = false
  description = "Is this node a HADR secondary one"
}

variable "primary_node_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the primary node output. This variable must only be defined for the secondary node."
  default     = null
}

variable "primary_node_sonarw_private_key" {
  type        = string
  description = "Private key of the sonarw user taken from the primary node output. This variable must only be defined for the secondary node."
  default     = null
}

variable "proxy_info" {
  type = object({
    proxy_address     = string
    proxy_ssh_key_path = string
    proxy_ssh_user    = string
  })
  description = "Proxy address used for ssh to the sonar instance, Proxy ssh key file path and Proxy ssh user. Keep empty if no proxy is in use"
  default     = {
    proxy_address     = null
    proxy_ssh_key_path = null
    proxy_ssh_user    = null
  }
}

variable "hub_sonarw_public_key" {
  type        = string
  description = "Public key of the sonarw user taken from the primary Hub output. This variable must only be defined for the Gateway. Used, for example, in federation."
  nullable    = false
}

variable "skip_instance_health_verification" {
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}