variable "dsf_primary_ip" {
  type        = string
  description = "IP of the primary Hub or Gateway, can be public or private"
  nullable    = false
}

variable "dsf_primary_private_ip" {
  type        = string
  description = "Private IP of the primary Hub or Gateway"
  nullable    = false
}

variable "dsf_secondary_ip" {
  type        = string
  description = "IP of the secondary Hub or Gateway, can be public or private"
  nullable    = false
}

variable "dsf_secondary_private_ip" {
  type        = string
  description = "Private IP of the secondary Hub or Gateway"
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

variable "proxy_host" {
  type        = string
  default     = null
  description = "Proxy host used for ssh"
}

variable "proxy_private_ssh_key_path" {
  type        = string
  default     = null
  description = "Proxy private ssh key file path"
}

variable "proxy_ssh_user" {
  type        = string
  default     = null
  description = "Proxy ssh user"
}
