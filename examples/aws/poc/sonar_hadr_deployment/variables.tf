variable "additional_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "sonar_version" {
  type        = string
  default     = "4.17"
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  validation {
    condition     = !startswith(var.sonar_version, "4.9.") && !startswith(var.sonar_version, "4.10.")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket location of the DSF installation software. s3_key is the full path to the tarball file within the bucket, for example, 'prefix/jsonar-x.y.z.w.u.tar.gz'"
  default     = null
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of DSF Agentless Gateways"
  validation {
    condition     = var.gw_count > 0
    error_message = "The gw_count value must be greater than 0."
  }
}

variable "password" {
  sensitive   = true
  type        = string
  default     = null # Random
  description = "Password for all users and components including internal communication (Agentless Gateways and Hub) and also to DSF Hub web console (Randomly generated if not set)"
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub web console CIDR blocks in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the subnet (x.x.x.0/24) of the public IP of the computer where the Terraform is run is used Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "IP ranges from which SSH access to the deployed DSF nodes will be allowed"
  default     = []
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "vpc_ip_range" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPC CIDR range"
}

variable "private_subnets" {
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  description = "VPC private subnets CIDR range"
}

variable "public_subnets" {
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
  description = "VPC public subnets CIDR range"
}

variable "subnet_ids" {
  type = object({
    main_hub_subnet_id = string
    dr_hub_subnet_id   = string
    main_gws_subnet_id = string
    dr_gws_subnet_id   = string
    db_subnet_ids      = list(string)
  })
  default     = null
  description = "The IDs of an existing subnets to deploy resources in. Keep empty if you wish to provision new VPC and subnets. db_subnet_ids can be an empty list only if no databases should be provisioned"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.main_hub_subnet_id != null && var.subnet_ids.dr_hub_subnet_id != null && var.subnet_ids.main_gws_subnet_id != null && var.subnet_ids.dr_gws_subnet_id != null && var.subnet_ids.db_subnet_ids != null, false)
    error_message = "Value must either be null or specified for all"
  }
  validation {
    condition     = var.subnet_ids == null || try(alltrue([for subnet_id in values({ for k, v in var.subnet_ids : k => v if k != "db_subnet_ids" }) : length(subnet_id) >= 15 && substr(subnet_id, 0, 7) == "subnet-"]), false)
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "hub_instance_type" {
  type        = string
  default     = "r6i.4xlarge"
  description = "Ec2 instance type for the DSF Hub"
}

variable "agentless_gw_instance_type" {
  type        = string
  default     = "r6i.2xlarge"
  description = "Ec2 instance type for the Agentless Gateway"
}

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 500
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "agentless_gw_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "simulation_db_types_for_agentless" {
  type        = list(string)
  default     = ["RDS MySQL"]
  description = "Types of databases to provision and onboard to an Agentless Gateway for simulation purposes. Available types are: 'RDS MySQL', 'RDS PostgreSQL' and 'RDS MsSQL'. 'RDS MsSQL' includes simulation data."
  validation {
    condition = alltrue([
      for db_type in var.simulation_db_types_for_agentless : contains(["RDS MySQL", "RDS MsSQL", "RDS PostgreSQL"], db_type)
    ])
    error_message = "Value must be a subset of: ['RDS MySQL', 'RDS MsSQL', 'RDS PostgreSQL']"
  }
}
