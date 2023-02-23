variable "dsf_primary_ip" {
  type        = string
  description = "IP of the primary Hub, can be public or private"
  nullable    = false
}

variable "dsf_primary_private_ip" {
  type        = string
  description = "Private IP of the primary Hub"
  nullable    = false
}

variable "dsf_secondary_ip" {
  type        = string
  description = "IP of the secondary Hub, can be public or private"
  nullable    = false
}

variable "dsf_secondary_private_ip" {
  type        = string
  description = "Private IP of the secondary Hub"
  nullable    = false
}

variable "ssh_key_path" {
  type        = string
  description = "SSH key path"
  nullable    = false
}

variable "ssh_key_path_secondary" {
  type        = string
  description = "SSH key path for secondary. Keep empty if the key is identical to primary one"
  default     = null
}

variable "ssh_user" {
  type        = string
  description = "SSH user"
  nullable    = false
}

variable "ssh_user_secondary" {
  type        = string
  description = "SSH user for secondary. Keep empty if the user is identical to primary one"
  default     = null
}

variable "proxy_info" {
  type = object({
    proxy_address              = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user             = string
  })
  description = "Proxy address, private key file path and user used for ssh to a private DSF node. Keep empty if a proxy is not used."
  default     = {
    proxy_address              = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user             = null
  }
}
