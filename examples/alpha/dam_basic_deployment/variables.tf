variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "dam_version" {
  description = "The DAM version to install"
  type        = string
  default     = "14.11.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "gw_count" {
  type        = number
  default     = 2
  description = "Number of DSF Agent Gateways"
  validation {
    condition     = var.gw_count >= 2
    error_message = "Must be greater or equal to 2"
  }
}

variable "agent_count" {
  type        = number
  default     = 1
  description = "The number of compute instances to provision, each with a database and a monitoring agent"
}

variable "web_console_admin_password" {
  default   = null # Random
  sensitive = true
  type      = string
  # default     = null # Random
  description = "Admin password (Randomly generated if not set)"
}

variable "web_console_cidr_list" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DAM web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF DAM web console as a public website. It is recommended to specify a more restricted IP and CIDR range"
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}

variable "vpc_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR range"
}

variable "private_subnets_cidr_list" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "VPC private subnet CIDR range"
}

variable "public_subnets_cidr_list" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "VPC public subnet CIDR range"
}

variable "gw_group_id" {
  type        = string
  default     = null # None
  description = "Gw group id. Keep empty for random generated one"
}

variable "license_file" {
  type = string
  validation {
    condition     = fileexists(var.license_file)
    error_message = "File doesn't exist"
  }
  description = "DAM license file path"
}

variable "subnet_ids" {
  type = object({
    mx_subnet_id = string
    gw_subnet_id = string
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.mx_subnet_id != null && var.subnet_ids.gw_subnet_id != null, false)
    error_message = "Value must either be null or specified for all"
  }
}

variable "hub_details" {
  description = "Details of the DSF hub for sending audit logs"
  type = object({
    address      = string
    port         = number
    access_token = string
  })
  default = null
}

variable "large_scale_mode" {
  type        = bool
  description = "DAM large scale mode"
  default     = false
}
