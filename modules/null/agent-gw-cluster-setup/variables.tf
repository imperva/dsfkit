variable "cluster_name" {
  type        = string
  description = "The name of the Cluster to provision"
}

variable "gateway_group_name" {
  type        = string
  description = "The name of the Gateway Group which holds the Agent Gateways to add to the newly provisioned Cluster. There must be at least 2 Agent Gateways in the Gateway Group, which is the minimum number required to setup a Cluster."
}

variable "delete_gateway_group" {
  type        = bool
  default     = true
  description = "Determines whether to delete the Gateway Group after all the Agent Gateways were moved from it to the Cluster"
}

variable "mx_details" {
  description = "Details of the MX for API calls"
  type = object({
    address  = string
    port     = number
    user     = string
    password = string
  })
}
