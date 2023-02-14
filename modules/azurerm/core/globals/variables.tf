variable "sonar_version" {
  type    = string
  default = "4.10"
  validation {
    condition     = contains(["4.9", "4.10"], var.sonar_version)
    error_message = "The sonar_version value must be from the list [\"4.9\", \"4.10\"]"
  }
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
