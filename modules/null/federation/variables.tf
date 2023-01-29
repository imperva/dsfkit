variable "gws_info" {
  type = object({
    gw_ip_address           = string
    gw_private_ssh_key_path = string
    gw_ssh_user             = string
  })

  nullable    = false
  description = "GWs info"
}

variable "hub_info" {
  type = object({
    hub_ip_address           = string
    hub_private_ssh_key_path = string
    hub_ssh_user             = string
  })

  nullable    = false
  description = "Hub info"
}

variable "gws_proxy_info" {
  type = object({
    proxy_address = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user = string
  })

  description = "GWs proxy info"
  default     = {
    proxy_address     = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user    = null
  }
}

variable "hub_proxy_info" {
  type = object({
    proxy_address = string
    proxy_private_ssh_key_path = string
    proxy_ssh_user = string
  })

  description = "Hub proxy info"
  default     = {
    proxy_address     = null
    proxy_private_ssh_key_path = null
    proxy_ssh_user    = null
  }
}

# variable "binaries_location" {
#   type = object({
#     s3_bucket = string
#     s3_key    = string
#   })
#   description = "Changing this variable forces a re-federation process"# todo why we need this? 
#   nullable    = false
# }
