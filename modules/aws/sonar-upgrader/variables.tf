variable "agentless_gws" {
  type = list(object({
    main = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    })),
    dr = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    })),
    minor = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    }))
  }))

  default     = []
  description = "A list of the Agentless Gateways to upgrade and their details which are required in order to connect to them to perform the upgrade. The proxy is optional and all combinations are accepted: Main and DR and minor, main and DR, DR only, etc."
}

variable "dsf_hubs" {
  type = list(object({
    main = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    })),
    dr = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    })),
    minor = optional(object({
      host                        = string # IP or hostname, can be private or public
      ssh_user                    = string
      ssh_private_key_file_path   = string
      proxy = optional(object({
        host                      = string # IP or hostname, can be private or public
        ssh_user                  = string
        ssh_private_key_file_path = string
      }))
    }))
  }))

  default     = []
  description = "A list of the DSF Hubs to upgrade and their details which are required in order to connect to them to perform the upgrade. The proxy is optional and all combinations are accepted: Main and DR and minor, main and DR, DR only, etc."
}

variable "target_version" {
  type        = string
  default     = null
  description = "The Sonar target version to upgrade to. The lowest supported version is 4.10 from the second patch onward."
}

variable "connection_timeout" {
  type = number
  default = 90
  description = "Client connection timeout in seconds used for the SSH connections between the installer machine and the DSF nodes being upgraded. Its purpose is to ensure a uniform behavior across different platforms. Note that the SSH server in the DSF nodes may have its own timeout configurations which may override this setting."
}

variable "test_connection" {
  type        = bool
  default     = true
  description = "Whether to test the SSH connection to all DSF nodes being upgraded before starting the upgrade"
}

variable "run_preflight_validations" {
  type        = bool
  default     = true
  description = "Whether to run the preflight validations or skip them"
}

variable "run_upgrade" {
  type        = bool
  default     = true
  description = "Whether to run upgrade or skip it"
}

variable "run_postflight_validations" {
  type        = bool
  default     = true
  description = "Whether to run the postflight validations or skip them"
}

variable "clean_old_deployments" {
  type        = bool
  default     = false
  description = "Whether to clean old deployments after successful upgrade. In case postflight validations run and failed, old deployment directories cleaning will be skipped. This variable is not operational in this POC."
}


variable "stop_on_failure" {
  type        = bool
  default     = true
  description = "Whether to stop or continue to upgrade the next DSF nodes in case of failure on a DSF node"
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket location of the DSF installation software. s3_key is the full path to the tarball file within the bucket, for example, 'prefix/jsonar-x.y.z.w.u.tar.gz'"
  default     = {
    s3_bucket = "1ef8de27-ed95-40ff-8c08-7969fc1b7901"
    s3_region = "us-east-1"
    s3_key = null
  }
}
