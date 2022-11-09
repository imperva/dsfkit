variable "region" { 
    default = "us-east-2" 
}

variable "master_username" {
  type = string
  description = "Master username must contain 1–16 alphanumeric characters, the first character must be a letter, and name can not be a word reserved by the database engine."
  validation {
    condition = length(var.master_username) > 1
    error_message = "Master username name must be at least 1 characters"
  }
}

variable "master_password" {
  type = string
  description = "Master password must contain 8–41 printable ASCII characters, and can not contain /, \", @, or a space."
  validation {
    condition = length(var.master_password) > 7
    error_message = "Master password name must be at least 8 characters"
  }
}

variable "cluster_identifier" {
  type = string
  description = "Name of your Aurora cluster from 3 to 63 alphanumeric characters or hyphens, first character must be a letter, must not end with a hyphen or contain two consecutive hyphens, and must be unique for all DB clusters per AWS account, per AWS Region."
  validation {
    condition = length(var.cluster_identifier) > 3
    error_message = "Cluster identifier name must be at least 3 characters"
  }
}

variable "rds_subnet_ids" { 
    type = list
    description = "List of subnet_ids to make rds cluster available on."
}

variable "key_pair_pem_local_path" {
  type = string
  description = "Path to local key pair used to access dsf instances via ssh to run remote commands"
}
