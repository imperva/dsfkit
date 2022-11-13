variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "tarball_s3_bucket" {
  type    = string
  default = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "tarball_s3_key" {
  type    = string
  default = "jsonar-4.10.0.0.0-rc1_20221019194459.tar.gz"
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


variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_ip_range" {
  type    = string
  default = "10.0.0.0/16"
}