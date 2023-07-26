# variable "gw_list" {
#   type        = map(string)
#   default     = {}
# }

# variable "hub_list" {
#   type        = map(string)
#   default     = {}
# }

variable "gw_list" {
  type        = string
  default     = null
}

variable "target_gws_by_id" {
  type        = list(map(string))
  default     = []
}


variable "target_hubs_by_id" {
  type        = list(map(string))
  default     = []
}
  
  


variable "hub_list" {
  type        = string
  default     = null
}


variable "run_preflight_validation" {
    type        = bool
    default     = true
}
    
variable "run_postflight_validation" {
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
    
  