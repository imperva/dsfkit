variable "id" {
  type        = string
  default     = null
  description = "Id indexing the statistics item. Used to overide/update an entry"
}

variable "deployment_name" {
  type        = string
  description = "Deployment name"
  default = null
}

variable "artifact" {
  type        = string
  description = "Artifact"
  default = null
}

variable "product" {
  type        = string
  description = "Product"
  default = null
}

variable "resource_type" {
  type        = string
  description = "Resource type"
  default = null
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

variable "location" { 
  type = string
  description = "Location"
  default = null
}