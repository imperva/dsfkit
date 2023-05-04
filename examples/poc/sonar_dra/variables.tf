variable "deployment_name" {
  type        = string
  default     = "imperva-dsf-dra"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
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

# todo - check whether it should be different than the public subnets for the sonar / dam
variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "VPC public subnet cidr range"
}

variable "subnet_ids" {
  type = object({
    admin_subnet_id = string
    analytics_subnet_id  = string
    db_subnet_ids = list(string)
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.admin_subnet_id != null && var.subnet_ids.analytics_subnet_id != null && var.subnet_ids.db_subnet_ids != null, false)
    error_message = "Value must either be null or specified for all"
  }
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}

variable "admin_instance_type" {
    type = string
    default = "m4.xlarge"
}

variable "analytics_instance_type" {
  type = string
  default = "m4.xlarge"
}

variable "admin_ami_id" {
    type = string
    description = "DRA admin AMI ID in region"
    # default = "ami-05d03d9f0e5f8c9f9"
}

variable "analytics_ami_id" {
    type = string
    description = "DRA analytics AMI ID in region"
    # default = "ami-06c0b1409371fd42f"
}

variable "analytics_server_count" {
  type        = number
  default     = 1
  description = "Number of Analytics Servers"
}

variable "admin_analytics_registration_password" {
    type = string
    description = "Password to be used to register Analtyics server to Admin Server"
    default = null
}

variable "archiver_user" {
    type = string
    description = "User to be used to upload archive files for analysis"
    default = null
}

variable "archiver_password" {
    type = string
    description = "Password to be used to upload archive files for analysis"
    default = null
}

variable "analytics_group_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF gw compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 75
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "admin_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 250
    provisioned_iops = 0
    throughput       = 125
  }
}
