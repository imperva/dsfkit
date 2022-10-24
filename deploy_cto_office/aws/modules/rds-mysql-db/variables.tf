variable "region" { 
    default = "us-east-2" 
}

variable "username" {
  type = string
  description = "Username must contain 1–16 alphanumeric characters, the first character must be a letter, and name can not be a word reserved by the database engine."
  validation {
    condition = length(var.username) > 1
    error_message = "Master username name must be at least 1 characters."
  }
}

variable "password" {
  type = string
  description = "Password must contain 8–41 printable ASCII characters, and can not contain /, \", @, or a space."
  validation {
    condition = length(var.password) > 7
    error_message = "Master password name must be at least 8 characters."
  }
}

variable "db_identifier" {
  type = string
  description = "Name of your MySQL DB from 3 to 63 alphanumeric characters or hyphens, first character must be a letter, must not end with a hyphen or contain two consecutive hyphens."
  validation {
    condition = length(var.db_identifier) > 3
    error_message = "DB identifier name must be at least 3 characters."
  }
}

variable "db_name" { 
    type = string
    description = "Name of the database to create and apply init sql file to"
}

variable "init_sql_file_path" { 
    type = string
    description = "Local db sql init file()."
}

variable "rds_subnet_ids" { 
    type = list
    description = "List of subnet_ids to make rds cluster available on."
}

variable "key_pair_pem_local_path" {
  type = string
  description = "Path to local key pair used to access dsf instances via ssh to run remote commands"
}

variable "security_group_ingress_cidrs" { 
    type = list
    description = "List of allowed ingress cidr ranges for access to the RDS cluster"
}
