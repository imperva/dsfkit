variable "ciphertrust_instances" {
  type = list(object({
    host            = string
    public_address  = string
  }))
  description = "List of CipherTrust Manager instances to form a cluster. Each instance should have a host and a public_address."
  validation {
      condition     = length(var.ciphertrust_instances) > 1
      error_message = "At least two CipherTrust Manager instances are required to form a cluster."
  }
}

variable "ddc_node_setup" {
  type = object({
    enabled      = bool
    node_address = string
  })
  description = "Configuration for DDC node setup. Set 'enabled' to true to run setup for the given 'node_address' as the DDC active node in the cluster."
  default = {
    enabled      = false
    node_address = ""
  }
}

variable "cm_details" {
  sensitive = true
  type = object({
      user     = string
      password = string
  })
  description = "Details for the CipherTrust Manager, including user and password."
  default = {
    user     = null
    password = null
  }
}