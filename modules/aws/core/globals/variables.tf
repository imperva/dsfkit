variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

# TODO Improve what we do here with the versions
variable "sonar_version" {
  type        = string
  default     = "4.11"
  description = "The Sonar version to install. Supported versions are: 4.9 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  validation {
    condition     = contains(["4.9", "4.10", "4.10.0.0", "4.10.0.1", "4.11", "4.11.0.0", "4.12.0.10", "4.12"], var.sonar_version)
    error_message = "The sonar_version value must be from the list [\"4.9\", \"4.10\", \"4.10.0.0\", \"4.10.0.1\", \"4.11\", \"4.11.0.0\", \"4.12.0.10\", \"4.12\"]"
  }
}

variable "tarball_s3_bucket" {
  type = object({
    bucket = string
    region = string
  })
  default = {
    bucket = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
    region = "us-east-1"
  }
  description = "S3 bucket containing the installation tarballs. Use default to get Imperva's bucket"
}

variable "tarball_s3_key" {
  type        = string
  default     = null
  description = "Name of the installation file in s3 bucket. Keep empty if you prefer to use the sonar_version variable"
}

# TODO Add validation
variable "dra_version" {
  type        = string
  default     = "4.11"
  description = "The DRA version to install. Supported versions are 4.11.0.10 and up. Both long and short version formats are supported, for example, 4.11.0.10 or 4.11. The short format maps to the latest patch."
}