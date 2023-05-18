variable "friendly_name" {
  type        = string
  description = "Friendly name to identify all resources"
  default     = "imperva-dsf-agent-monitored-db"

  validation {
    condition     = length(var.friendly_name) >= 3
    error_message = "Must be at least 3 characters long"
  }
  validation {
    condition     = can(regex("^\\p{L}.*", var.friendly_name))
    error_message = "Must start with a letter"
  }
}

variable "subnet_id" {
  type        = string
  description = "Subnet id for the DSF MX instance"
  validation {
    condition     = length(var.subnet_id) >= 15 && substr(var.subnet_id, 0, 7) == "subnet-"
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

variable "key_pair" {
  type        = string
  description = "Key pair for the ec2 instance"
}

variable "security_group_ids" {
  type        = list(string)
  description = "Additional Security group ids for the ec2 instance"
  default     = []
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the ec2 instance"
  default     = []
}

variable "db_type" {
  type        = string
  default     = null
  description = "DB type to provision on EC2 with an agent, available types are: ['PostgreSql', 'MySql', 'MariaDB']"
  validation {
    condition     = var.db_type == null || try(contains(["PostgreSql", "MySql", "MariaDB"], var.db_type), false)
    error_message = "Valid values should contain at least one of the following: ['PostgreSql', 'MySql', 'MariaDB']"
  }
}

variable "os_type" {
  type        = string
  default     = null
  description = "Os type to provision as EC2"
  validation {
    condition     = var.os_type == null || try(contains(["Red Hat", "Ubuntu"], var.os_type), false)
    error_message = "Valid values should contain at least one of the following: 'Red Hat', 'Ubuntu']"
  }
}

variable "registration_params" {
  type = object(
    {
      agent_gateway_host = string
      secure_password    = string
      site               = string
      server_group       = string
    }
  )
  description = "Regisration parameters for DAM agent"
}

variable "binaries_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 DSF DAM agent installation location"
  default     = null
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
