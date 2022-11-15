variable "hub_address" {
  type        = string
  description = "Hub address"
  nullable    = false
}

variable "assignee_gw" {
  type        = string
  description = "jsonar uid of the assignee gw"
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

variable "hub_ssh_key_path" {
  type        = string
  description = "Hub ssh key path"
  nullable    = false
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
  })
  description = "database details"
  nullable    = false
}
