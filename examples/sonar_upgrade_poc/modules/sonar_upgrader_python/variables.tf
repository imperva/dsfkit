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
  description = "A list of the Agentless Gateways to upgrade and their details which are required in order to connect to them to perform the upgrade. The proxy is optional."
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
  description = "A list of the DSF Hubs to upgrade and their details which are required in order to connect to them to perform the upgrade. The proxy is optional."
}

variable "target_version" {
  type        = string
  default     = null
  description = "The Sonar target version to upgrade to. The lowest supported version is 4.10 from the second patch onward."
}

variable "run_preflight_validations" {
  type        = bool
  default     = true
  description = "Whether to run the preflight validations or skip them"
}
    
variable "run_postflight_validations" {
  type        = bool
  default     = true
  description = "Whether to run the postflight validations or skip them"
}

variable "custom_validations_scripts" {
  type        = list(string)
  default     = []
  description = "A list of scripts with custom validations. This variable is not operational in this POC."
}

variable "run_upgrade" {
  type        = bool
  default     = true
  description = "Whether to run upgrade or skip it"
}
