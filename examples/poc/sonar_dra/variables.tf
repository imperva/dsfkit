variable "region" {
    type = string
    description = "AWS region for placement of VPC"
    default = "us-west-1"
}

variable "vpc_cidr" {
    type=string
    default = "10.0.0.0/16"
}

variable "instance_type" {
    type = string
    default = "m4.xlarge"
}

variable "key" {
    type = string
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

variable "registration_password" {
    type = string
    description = "Password to be used to register Analtyics server to Admin Server"
    default = "yourpasswordhere"
}

variable "analytics_user" {
    type = string
    description = "User to be used to upload archive files for analysis"
    default = "your_scp_user"
}

variable "analytics_password" {
    type = string
    description = "Password to be used to upload archive files for analysis"
    default = "yourpasswordhere"
}