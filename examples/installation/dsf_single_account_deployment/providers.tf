## must have default provider
#provider "aws" {
#  profile = var.aws_profile
#  region  = var.aws_region_1
#}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region_1
  alias   = "provider-1"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region_2
  alias   = "provider-2"
}
