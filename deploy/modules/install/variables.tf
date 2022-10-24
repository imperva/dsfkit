variable "instance_address" {
  type = string
  description = "IP address or FQDN of the DSF instance. Must be accessible using SSH by the Terraform workstation"
  nullable = false
}

variable "dsf_type" {
  type    = string
  validation {
    condition     = contains(["hub", "gw"], var.dsf_type)
    error_message = "Allowed values for dsf type \"hub\" or \"gw\"."
  }
  nullable = false
}

variable "installation_location" {
  type = object({
    s3_bucket = string
    s3_key = string
  })
  description = "S3 DSF installation location"
  nullable = false
}

variable "admin_password" {
  type = string
  sensitive = true
  description = "Admin password"
  validation {
    condition = length(var.admin_password) > 8
    error_message = "Admin password must be at least 8 characters"
  }
  nullable = false
}

variable "name" {
  type = string
  default = "imperva-dsf-hub"
  description = "Deployment name"
  validation {
    condition = length(var.name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

variable "ssh_key_pair_path" {
  type = string
  description = "SSH key path for DSF instance"
  nullable = false
}

variable "sonarw_public_key" {
  type = string
  description = "SSH public key for sonarw user"
  nullable = false
}

variable "sonarw_secret_name" {
  type = string
  description = "Secret name for sonarw ssh key"
  nullable = false
}

variable "proxy_address" {
  type = string
  description = "Proxy address used for ssh"
  default = null
}