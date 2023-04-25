variable "deployment_name" {
  type        = string
  default     = "impv-dsf-dra"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}


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


variable "analitycs_group_ebs_details" {
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

variable "subnet_id" {
  type = string
  default = null
  
}
