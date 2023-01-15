variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-hub"
  description = "Friendly name, EC2 Instace Name"
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
  description = "Is this node a hadr secondary one"
}

variable "hadr_main_hub_federation_public_key" {
  type        = string
  description = "Public key of sonarw taken from the main hub output. This var must be defined for hadr seconday node"
  default     = null
}

variable "hadr_main_hub_federation_private_key" {
  type        = string
  description = "Private key of sonarw taken from the main hub output. This var must be defined for hadr seconday node"
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

variable "ami_name_tag" {
  type        = string
  default     = null
  description = "Ami name to use as base image for the compute instance"
}

variable "ami_user" {
  type        = string
  default     = null
  description = "Ami user to use for SSH to the compute instance"
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to DSF hub. Keep empty if you wish to create a new role."
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the EC2 instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}
