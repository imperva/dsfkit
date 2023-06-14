variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "key_name_prefix" {
  type = string
}

variable "create_private_key" {
  type    = bool
  default = true
}

variable "private_key_filename" {
  type = string
}