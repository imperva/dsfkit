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

variable "usc_access_token" {
  type        = string
  description = "DSF Hub access token with USC scope"
}

variable "cloud_account_data" {
  type = object({
    id = object({
      name  = string
      value = string
    })
    name             = string
    type             = string
    connections_data = list(any)
  })
  description = "Cloud account data"
}

variable "cloud_account_additional_data" {
  type        = any
  description = "Cloud account additinal data"
  default     = {}
}

variable "database_data" {
  type = object({
    server_type = string
    id = object({
      name  = string
      value = string
    })
    name     = string
    hostname = string
    port     = number
  })
}

variable "database_additional_data" {
  type        = any
  description = "Database additinal data"
  default     = {}
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

variable "enable_audit" {
  type        = bool
  description = "Enable audit for asset"
  default     = true
}
