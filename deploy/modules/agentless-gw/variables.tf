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

variable "sg_ingress_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the DSF agentless gw instance for ssh and internal protocols"
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name        = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable    = false
}

variable "installation_location" {
  type = object({
    s3_bucket = string
    s3_key    = string
  })
  description = "S3 DSF installation location"
  nullable    = false
}

variable "hub_federation_public_key" {
  type        = string
  description = "Public key of sonarw taken from the main hub output"
  nullable    = false
}

variable "proxy_address" {
  type        = string
  description = "Proxy address used for ssh for private gw (Usually hub address)"
  default     = null
}

variable "proxy_ssh_key_path" {
  type        = string
  default     = null
  description = "Proxy ssh key path. Keep empty if no proxy is in use or in case the proxy's key is similar to gw's"
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password"
  validation {
    condition     = length(var.admin_password) > 8
    error_message = "Admin password must be at least 8 characters"
  }
  nullable = false
}

variable "proxy_private_key" {
  type        = string
  description = "proxy_private_key"
  nullable    = false
}

variable "ami_name_tag" {
  type        = string
  default     = null
  description = "Ami name to use as base image for the compute instance"
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to DSF gw. Keep empty if you wish to create a new role."
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/80035.htm"
}
