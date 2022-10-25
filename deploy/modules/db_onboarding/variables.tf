variable "hub_address" {
  type = string
  description = "Hub address"
  nullable = false
}

variable "assignee_gw" {
  type = string
  description = "jsonar uid of the assignee gw"
  nullable = false
}

variable "hub_ssh_key_path" {
  type = string
  description = "Hub ssh key path"
  nullable = false
}
