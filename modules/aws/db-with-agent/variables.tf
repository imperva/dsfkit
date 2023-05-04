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
    condition     = length(var.subnet_id) >= 16 && substr(var.subnet_id, 0, 7) == "subnet-"
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

variable "sg_ssh_cidr" {
  type        = list(string)
  description = "List of allowed ingress CIDR patterns allowing ssh protocols to the ec2 instance"
  default     = []
}

variable "db_type" {
  type        = string
  default     = "PostgreSql"
  description = "DB type to provision on EC2 with an agent, available types are: ['PostgreSql', 'MySql', 'MariaDB']"
  validation {
    condition     = contains(["PostgreSql", "MySql", "MariaDB"], var.db_type)
    error_message = "Valid values should contain at least one of the following: ['PostgreSql', 'MySql', 'MariaDB']"
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
  default = {
    s3_bucket = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
    s3_key    = "Imperva-ragent-UBN-px86_64-b14.6.0.60.0.636085.bsx"
    s3_region = "us-east-1"
  }
}
