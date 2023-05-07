variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-dra-admin"
  description = "Friendly name, EC2 Instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
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

variable "security_group_id" {
  type        = string
  default     = null
  description = "Security group id for the DRA Admin instance. In case it is not set, a security group will be created automatically."
  validation {
    condition     = var.security_group_id == null ? true : (substr(var.security_group_id, 0, 3) == "sg-")
    error_message = "Security group id is invalid. Must be sg-********"
  }
}

variable "attach_public_ip" {
  type        = bool
  default     = false
  description = "Create public IP for the instance"
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
  description = "IAM role to assign to the DRA Admin. Keep empty if you wish to create a new role."
}

variable "ssh_user" {
  type    = string
  default = "ec2-user"
}
