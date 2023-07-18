variable "sonar_version" {
  type        = string
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  nullable    = false
  validation {
    condition     = !startswith(var.sonar_version, "4.9.") && !startswith(var.sonar_version, "4.10.")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}

variable "hub_info" {
  type = object({
    hub_ip_address           = string
    hub_private_ssh_key_path = string
    hub_ssh_user             = string
  })

  nullable    = false
  description = "Hub info"
}

variable "hub_proxy_info" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })

  description = "Proxy address, private key file path and user used for ssh to a private DSF Hub. Keep empty if a proxy is not used."
  default = {
    proxy_address              = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user             = null
  }
}

variable "assignee_gw" {
  type        = string
  description = "jsonar uid of the assignee DSF Agentless Gateway"
  nullable    = false
  validation {
    condition     = length(var.assignee_gw) >= 35
    error_message = "Should be uuid in the form of xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}

variable "assignee_role" {
  type        = string
  description = "IAM role of the asset assignee"
  nullable    = false
}

variable "usc_access_token" {
  type        = string
  description = "DSF Hub access token with USC scope"
}

variable "database_details" {
  type = object({
    db_username   = string
    db_password   = string
    db_arn        = string
    db_port       = number
    db_engine     = string
    db_identifier = string
    db_address    = string
    db_name       = string
  })
  description = "database details"
  nullable    = false

  validation {
    condition     = contains(["mysql", "sqlserver-ex"], var.database_details.db_engine)
    error_message = "Allowed values for db engine: \"mysql\", \"sqlserver-ex\""
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

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
