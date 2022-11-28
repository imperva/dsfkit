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
  default = "jsonar-4.10.0.0.0-rc8_20221123154044.tar.gz"
}

variable "gw_count" {
  type    = number
  default = 1
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

variable "additional_install_parameters" {
  default = ""
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

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes"
  default = {
    disk_size        = 500
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "gw_group_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Gw group compute instance volume attributes"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}