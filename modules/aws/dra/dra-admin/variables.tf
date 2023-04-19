variable "region" {
    type = string
    description = "AWS region for placement of VPC"
}


variable "deployment_name" {
    type = string
    description = "deployment_name"
}

variable "instance_type" {
    type = string
    default = "m4.xlarge"
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}


variable "admin_ami_id" {
    type = string
    description = "DRA admin AMI ID in region"
    # default = "ami-05d03d9f0e5f8c9f9"
}

variable "admin_analytics_registration_password" {
    type = string
    description = "Password to be used to register Analtyics server to Admin Server"
}

variable "subnet_id" {
    type = string
    description = "subnet_id"
}


variable "vpc_security_group_ids" {
    type = list(string)
    description = "vpc_security_group_ids"
    default     = null
}


variable "vpc_id" {
    type = string
    description = "vpc_id"
}


variable "vpc_cidr" {
    type = string
    description = "vpc_cidr"
}

variable "ebs" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Compute instance volume attributes"
  default = null
}