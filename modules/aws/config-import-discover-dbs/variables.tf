variable "dsf_iam_role_name" {
  type        = string
  default     = null
  description = "DSF base ec2 IAM role name"
}

variable "hub_ip" {
  type        = string
  description = "IP address or hostname of the hub used to connect via ssh and run remote comnmands"
}

variable "hub_uuid" {
  type        = string
  description = "Unique identifier for the hub"
}

variable "hub_display_name" {
  type        = string
  description = "Display name for the hub"
}

variable "gw1_uuid" {
  type        = string
  description = "Unique identifier for gateway 1"
}

variable "gw1_display_name" {
  type        = string
  description = "Display name for gateway 1"
}

variable "gw1_iam_role" {
  type        = string
  description = "IAM role for gateway 1"
}

variable "key_pair_pem_local_path" {
  type        = string
  description = "Path to local key pair used to access dsf instances via ssh to run remote commands"
}
