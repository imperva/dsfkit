terraform {
  required_version = ">= 1.3.1, < 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
    local = {
      version = "~> 2.1"
    }
  }
}
