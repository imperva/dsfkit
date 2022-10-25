variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "tarball_s3_bucket" {
  type    = string
  default = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
}

variable "tarball_s3_key" {
  type    = string
  default = "jsonar-4.10.0.0.0-dev_20221006123138.tar.gz"
}

variable "gw_count" {
  type    = number
  default = 1
}

variable "admin_password" {
  sensitive = true
  type    = string
  default = null # Random
}

variable "web_console_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "workstation_cidr" {
  type    = list(string)
  default = null
}
