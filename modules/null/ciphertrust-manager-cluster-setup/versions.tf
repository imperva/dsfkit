terraform {
  required_version = ">= 1.3.1, < 1.17.0"

  required_providers {
    ciphertrust = {
      source  = "ThalesGroup/ciphertrust"
      version = "~> 0.11.1"
    }
  }
}
