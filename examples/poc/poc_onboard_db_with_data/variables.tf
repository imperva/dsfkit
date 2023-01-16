variable "deployment_name" {
  type    = string
  default = "imperva-dsf"
}

# do a map of db types to the full objects + add more db types
variable "onboarded_db_types" {
  type = object({
    db_type        = string
    db_identifier  = string
    snapshot_identifier  = string
    instance_class = string
  })
  description = "Optional DB types to onboard"
  default = ({
    db_type        = "SQL Server"
    db_identifier  = "se-lab-mssql-db"
    snapshot_identifier = "arn:aws:rds:us-east-1:112114489393:snapshot:se-lab-mssql-snapsho*"
    #    snapshot_identifier = "arn:aws:rds:us-east-1:112114489393:snapshot:se-lab-mssql-snapshot"
    #    db_identifier  = "hadar-mssql-db"
    #    db_identifier  = "hadar-mssql-snapshot"
    instance_class = "db.t3.small"
  })
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing hub ssh and debugging access"
}


## do a map of db types to the full objects + add more db types
#variable "onboarded_db_types" {
#  type = object({
#    db_type        = string
#    db_identifier  = string
#    instance_class = string
#  })
#  description = "Optional DB types to onboard"
#  default = ({
#    db_type        = "Aurora MySQL"
#    db_identifier  = "hadar-db"
#    #    db_identifier  = "hadar-db-snapshot"
#    instance_class = "db.t3.small"
#  })
#}






#variable "tarball_s3_bucket" {
#  type        = string
#  default     = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
#  description = "S3 bucket containing installation tarball"
#}
#
#variable "sonar_version" {
#  type    = string
#  default = "4.10"
#  validation {
#    condition     = contains(["4.10"], var.sonar_version)
#    error_message = "The sonar_version value must be '4.10'."
#  }
#}
#
#variable "tarball_s3_key_map" {
#  type = map(string)
#  default = {
#    "4.10" = "jsonar-4.10.0.0.0.tar.gz"
#  }
#  description = "S3 object key for installation tarball"
#}
