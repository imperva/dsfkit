variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

variable "tarball_s3_bucket" {
  type        = string
  default     = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
  description = "S3 bucket containing installation tarball"
}

variable "sonar_version" {
  type    = string
  default = "4.10"
}

variable "tarball_s3_key" {
  type        = string
  default     = "jsonar-4.10.0.0.0-rc8_20221123154044.tar.gz"
  description = "S3 object key for installation tarball"
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of agentless gateways"
}

variable "admin_password" {
  sensitive   = true
  type        = string
  default     = null # Random
  description = "Admin password (Random generated if not set)"
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowing DSF hub web console access"
}

variable "database_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing dummy database access"
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "vpc_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC cidr range"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "VPC private subnet cidr range"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "VPC public subnet cidr range"
}

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 250
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
  description = "DSF gw compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.9-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 75
    provisioned_iops = 0
    throughput       = 125
  }
}