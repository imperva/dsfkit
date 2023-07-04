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

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.103.0/24", "10.0.104.0/24"]
  description = "VPC public subnet cidr range"
}

variable "subnet_ids" {
  type = object({
    admin_subnet_id     = string
    analytics_subnet_id = string
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets."
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.admin_subnet_id != null && var.subnet_ids.analytics_subnet_id != null, false)
    error_message = "Value must either be null or specified for all fields"
  }
  validation {
    condition     = var.subnet_ids == null || try(alltrue([for subnet_id in values(var.subnet_ids) : length(subnet_id) >= 15 && substr(subnet_id, 0, 7) == "subnet-"]), false)
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DRA Admin web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the public IP of the computer where the Terraform is run is used. Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "allowed_ssh_cidrs_to_admin" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing SSH access to the Admin Server"
  validation {
    condition     = alltrue([for item in var.allowed_ssh_cidrs_to_admin : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "allowed_ssh_cidrs_to_analytics" {
  type        = list(string)
  description = "List of ingress CIDR patterns allowing SSH access to the Analytics Server"
  validation {
    condition     = alltrue([for item in var.allowed_ssh_cidrs_to_analytics : can(cidrnetmask(item))])
    error_message = "Each item of this list must be in a valid CIDR block format. For example: [\"10.106.108.0/25\"]"
  }
  default = []
}

variable "admin_instance_type" {
  type        = string
  default     = "m4.xlarge"
  description = "Ec2 instance type for the Admin Server"
}

variable "analytics_instance_type" {
  type        = string
  default     = "m4.xlarge"
  description = "Ec2 instance type for the Analytics Server"
}

variable "dra_version" {
  type        = string
  default     = "4.12.0.10"
  description = "The DRA version to install. Supported versions are 4.11.0.10 and up. Both long and short version formats are supported, for example, 4.11.0.10 or 4.11. The short format maps to the latest patch."
  validation {
    condition     = contains(module.globals.dra_supported_versions, var.dra_version)
    error_message = "The dra_version value must be 4.11.0.10 or higher"
  }
}

variable "analytics_server_count" {
  type        = number
  default     = 1
  description = "Number of Analytics Servers"
}

variable "admin_registration_password" {
  type        = string
  description = "Password to be used to register Analtyics server to Admin Server"
  default     = null
}

variable "archiver_user" {
  type        = string
  description = "User to be used to upload archive files for analysis"
  default     = null
}

variable "archiver_password" {
  type        = string
  description = "Password to be used to upload archive files for analysis"
  default     = null
}

variable "admin_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Admin Server compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 260
    volume_type = "gp3"
  }
}

variable "analytics_group_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Analytics Server compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 1010
    volume_type = "gp3"
  }
}
