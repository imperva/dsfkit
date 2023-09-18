variable "sonar_version" {
  type        = string
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  nullable    = false
  validation {
    condition     = !startswith(var.sonar_version, "4.9") && !startswith(var.sonar_version, "4.10")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}

variable "dsf_main_ip" {
  type        = string
  description = "IP of the main DSF Hub or Agentless Gateway, can be public or private"
  nullable    = false
}

variable "dsf_main_private_ip" {
  type        = string
  description = "Private IP of the main DSF Hub or Agentless Gateway"
  nullable    = false
}

variable "dsf_dr_ip" {
  type        = string
  description = "IP of the DR DSF Hub or Agentless Gateway, can be public or private"
  nullable    = false
}

variable "dsf_dr_private_ip" {
  type        = string
  description = "Private IP of the DR DSF Hub or Agentless Gateway"
  nullable    = false
}

variable "ssh_key_path" {
  type        = string
  description = "SSH key path"
  nullable    = false
}

variable "ssh_key_path_dr" {
  type        = string
  description = "SSH key path for DR. Keep empty if the key is identical to main one"
  default     = null
}

variable "ssh_user" {
  type        = string
  description = "SSH user"
  nullable    = false
}

variable "ssh_user_dr" {
  type        = string
  description = "SSH user for DR. Keep empty if the user is identical to main one"
  default     = null
}

variable "proxy_info" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })
  description = "Proxy address, private key file path and user used for ssh to a private DSF node. Keep empty if a proxy is not used."
  default = {
    proxy_address              = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user             = null
  }
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on a private DSF node. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}
