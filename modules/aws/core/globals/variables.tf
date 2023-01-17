variable "sonar_version" {
  type    = string
  default = "4.10"
  validation {
    condition     = contains(["4.9", "4.10"], var.sonar_version)
    error_message = "The sonar_version value must be from the list [\"4.9\", \"4.10\"]"
  }
}

variable "tarball_s3_bucket" {
  type        = string
  default     = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
  description = "S3 bucket containing the installation tarballs. Use default to get Imperva's bucket"
}

variable "tarball_s3_key" {
  type        = string
  default     = null
  description = "Name of the installation file in s3 bucket. Keep empty if you prefer to use the sonar_version variable"
}
