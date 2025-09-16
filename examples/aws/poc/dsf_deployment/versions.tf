terraform {
  required_version = ">= 1.3.1, < 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.23.0"
    }
    ciphertrust = {
      source  = "ThalesGroup/ciphertrust"
      version = "~> 0.11.1"
    }
    local = {
      version = "~> 2.1"
    }
  }
}
