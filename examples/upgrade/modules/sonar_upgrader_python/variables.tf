
variable "target_agentless_gws" {
  type = list(object({
    ip                        = string # can be private or public
    ssh_user                  = string
    ssh_private_key_file_path = string
    proxy = object({
      ip                        = string # can be private or public
      ssh_user                  = string
      ssh_private_key_file_path = string
    })
  }))

  default     = []
}

variable "target_hubs" {
  type        = list(map(string))
  default     = []
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
    
  

  variable "target_version" {
    type        = string
    default     = null
  }
    
  