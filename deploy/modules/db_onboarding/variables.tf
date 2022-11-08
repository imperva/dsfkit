variable "hub_address" {
  type        = string
  description = "Hub address"
  nullable    = false
}

variable "assignee_gw" {
  type        = string
  description = "jsonar uid of the assignee gw"
  nullable    = false
}

variable "assignee_role" {
  type        = string
  description = "IAM role of the asset assignee"
  nullable    = false
}

variable "hub_ssh_key_path" {
  type        = string
  description = "Hub ssh key path"
  nullable    = false
}

variable "database_sg_ingress_cidr" {
  type        = list(any)
  description = "List of allowed ingress cidr patterns for the database"
}

variable "public_subnets" {
  type        = list(any)
}

variable "deployment_name" {
  type = string
}

variable "onboarder_s3_bucket" {
  type    = string
  description = "S3 bucket to get the onboarder jar from"
}
