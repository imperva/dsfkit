variable "dsf_hub_primary_public_ip" {
  type        = string
  description = "dsf_hub_primary_public_ip"
  nullable    = false
}

variable "dsf_hub_primary_private_ip" {
  type        = string
  description = "dsf_hub_primary_private_ip"
  nullable    = false
}

variable "dsf_hub_secondary_public_ip" {
  type        = string
  description = "dsf_hub_secondary_public_ip"
  nullable    = false
}

variable "dsf_hub_secondary_private_ip" {
  type        = string
  description = "dsf_hub_secondary_private_ip"
  nullable    = false
}

variable "ssh_key_path" {
  type        = string
  description = "ssh_key_path"
  nullable    = false
}
