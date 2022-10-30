variable "main_region" {
  type = string
}

variable "main_region_profile" {
  type = string
}

variable "sec_region" {
  type = string
}

variable "sec_region_profile" {
  type = string
}

variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "admin_password" {
  sensitive = true
  type    = string
  default = "imp3rva12#"
}

variable "workstation_cidr" {
  type    = string
  default = null
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_key    = string
  })
  default = {
    s3_bucket = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
    # s3_key = "jsonar-4.8.a.tar.gz"
    s3_key = "jsonar-4.9.arc1_20220711223348.tar.gz"
  }
}
