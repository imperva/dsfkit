variable "region" {
    type = string
    description = "AWS region for placement of VPC"
}

variable "registration_password" {
    type = string
    description = "Password to be used to register Analtyics server to Admin Server"
}

variable "analytics_user" {
    type = string
    description = "User to be used to upload archive files for analysis"
}
variable "analytics_ami_id" {
    type = string
    description = "DRA analytics AMI ID in region"
    # default = "ami-06c0b1409371fd42f"
}

variable "admin_server_ip" {
    type = string
    description = "admin_server_private_ip"
   
}

variable "instance_type" {
    type = string
}

variable "key" {
    type = string
}

variable "analytics_password" {
    type = string
    description = "Password to be used to upload archive files for analysis"
    default = "yourpasswordhere"
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
}
