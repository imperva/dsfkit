variable "region" {
    type = string
    description = "AWS region for placement of VPC"
}

variable "deployment_name" {
    type = string
    description = "deployment_name"
}


variable "admin_analytics_registration_password_arn" {
    type = string
    description = "Password to be used to register Analtyics server to Admin Server"
}

variable "archiver_user" {
    type = string
    description = "User to be used to upload archive files for analysis"
}
variable "analytics_ami_id" {
    type = string
    description = "DRA analytics AMI ID in region"
    # default = "ami-06c0b1409371fd42f"
}

variable "admin_server_private_ip" {
    type = string
    description = "admin_server_private_ip"
   
}

variable "admin_server_public_ip" {
    type = string
    description = "admin_server_public_ip"
   
}

variable "instance_type" {
    type = string
}

variable "ssh_key_pair" {
  type = object({
    ssh_public_key_name       = string
    ssh_private_key_file_path = string
  })
  description = "SSH materials to access machine"

  nullable = false
}

variable "archiver_password" {
    type = string
    description = "Password to be used to upload archive files for analysis"
}

variable "vpc_security_group_ids" {
    type = list(string)
    description = "vpc_security_group_ids"
    default     = null
}



variable "subnet_id" {
    type = string
    description = "subnet_id"
}


variable "vpc_id" {
    type = string
    description = "vpc_id"
}



variable "vpc_cidr" {
    type = string
    description = "vpc_cidr"
    default = "0.0.0.0/0"
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

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the DRA Analytics. Keep empty if you wish to create a new role."
}
