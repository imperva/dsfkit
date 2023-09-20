variable "id" {
  type        = string
  default     = null
  description = "Id indexing the statistics item. Used to overide/update an entry"
}

variable "deployment_name" {
  type        = string
  description = "Deployment name"
}

variable "artifact" {
  type        = string
  description = "Artifact"
}

variable "product" {
  type        = string
  description = "Product"
}

variable "resource_type" {
  type        = string
  description = "Resource type"
}

variable "platform" {
  type        = string
  description = "Platform (aws/azure)"
}

variable "account_id" {
  type        = string
  description = "Account identifier"
}

variable "location" {
  type        = string
  description = "Location"
}

variable "status" {
  type        = string
  default     = null
  description = "Status"
}

variable "additional_info" {
  type        = map(any)
  default     = null
  description = "Additional info (json string)"
}
