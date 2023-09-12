variable "sonar_version" {
  type        = string
  default     = "4.12"
  description = "The Sonar version to install. Supported versions are: 4.9 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
}

variable "tarball_location" {
  type = object({
    storage_account = string
    container       = string
  })
  default = {
    storage_account = "eytanstorageaccount"
    container       = "sonar"
  }
  description = "Storage account and container containing the installation tarballs. Use default to get Imperva's one"
}

variable "tarball_blob" {
  type        = string
  default     = null
  description = "Name of the installation blob. Keep empty if you prefer to use the sonar_version variable"
}
