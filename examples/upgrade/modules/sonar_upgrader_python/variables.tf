variable "agentless_gws" {
  type = list(object({
    ip                        = string # can be private or public
    ssh_user                  = string
    ssh_private_key_file_path = string
    proxy = optional(object({
      ip                        = string # can be private or public
      ssh_user                  = string
      ssh_private_key_file_path = string
    }))
  }))

  default     = []
}

variable "dsf_hubs" {
  type = list(object({
    ip                        = string # can be private or public
    ssh_user                  = string
    ssh_private_key_file_path = string
    proxy = optional(object({
      ip                        = string # can be private or public
      ssh_user                  = string
      ssh_private_key_file_path = string
    }))
  }))

  default     = []
}

variable "target_version" {
  type        = string
  default     = null
}

variable "run_preflight_validations" {
    type        = bool
    default     = true
}
    
variable "run_postflight_validations" {
    type        = bool
    default     = true
}

variable "custom_validations_scripts" {
    type        = list(string)
    default     = []
}

variable "run_upgrade" {
  type        = bool
  default     = true
}
