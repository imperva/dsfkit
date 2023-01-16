terraform {
  required_version = ">= 1.3.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.63"
    }
  }
}

#provider "aws" {
#  region = "us-east-1"
#  alias = "prod_s3_region"
#}