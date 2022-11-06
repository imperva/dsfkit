variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "artifacts_s3_bucket" {
  type    = string
  default = "0ed58e18-0c0c-11ed-861d-0242ac120003"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "tarball_s3_key" {
  type    = string
  default = "jsonar-4.10.eytan_20221104161124.tar.gz"
}

variable "gw_count" {
  type    = number
  default = 2
}

variable "admin_password" {
  sensitive = true
  type      = string
  default   = null # Random
}

variable "web_console_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "database_cidr" {
  type    = list(string)
  default = null
}

variable "workstation_cidr" {
  type    = list(string)
  default = null
}
