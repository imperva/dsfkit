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

# variable "binaries_location" {
#   type = object({
#     s3_bucket = string
#     s3_key    = string
#   })
#   description = "Changing this variable forces a re-federation process"# todo why we need this? 
#   nullable    = false
# }
