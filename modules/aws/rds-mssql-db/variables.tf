variable "username" {
  type        = string
  description = "Master username must contain 1–16 alphanumeric characters, the first character must be a letter, and name can not be a word reserved by the database engine."
  default     = "admin"
  validation {
    condition     = length(var.username) > 1
    error_message = "Master username name must be at least 1 characters"
  }
}

variable "password" {
  type        = string
  description = "Master password must contain 8–41 printable ASCII characters, and can not contain /, \", @, or a space."
  default     = ""
  validation {
    condition     = length(var.password) == 0 || length(var.password) > 7
    error_message = "Master password name must be at least 8 characters"
  }
}

variable "identifier" {
  type        = string
  description = "Name of your MySQL DB from 3 to 63 alphanumeric characters or hyphens, first character must be a letter, must not end with a hyphen or contain two consecutive hyphens."
  default     = ""
  validation {
    condition     = length(var.identifier) == 0 || length(var.identifier) > 3
    error_message = "identifier name must be at least 3 characters"
  }
}

variable "name" {
  type        = string
  description = "Name of your rds instance"
  default     = ""
}

variable "db_audit_scripts_bucket_name" {
  type        = string
  description = "S3 bucket containing the DB audit scripts"
  default     = "ae309159-115c-4504-b0c2-03dd022f3368"
}

variable "init_sql_file_path" {
  type        = string
  default     = null
  description = "Local db sql init file()."
}

variable "rds_subnet_ids" {
  type        = list(string)
  description = "List of subnet_ids to make rds available on."
}

variable "security_group_ingress_cidrs" {
  type        = list(string)
  description = "List of allowed ingress cidr ranges for access to the RDS"
}

variable "role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the RDS SQL Server DB"
}

variable "friendly_name" {
  type        = string
  default     = "imperva-dsf-mssql"
  description = "Friendly name, MsSQL Instance Name"
  validation {
    condition     = length(var.friendly_name) > 3
    error_message = "Deployment name must be at least 3 characters"
  }
}

#variable "assignee_role" {
#  type        = string
#  description = "IAM role of the MsSQL"
#  nullable    = false
#}
