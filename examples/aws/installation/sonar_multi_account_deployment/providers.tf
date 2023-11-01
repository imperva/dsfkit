# must have default provider
provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_main
}

provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_main
  alias   = "hub-main"
}

provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_dr
  alias   = "hub-dr"
}

provider "aws" {
  profile = var.aws_profile_gw
  region  = var.aws_region_gw_main
  alias   = "gw-main"
}

provider "aws" {
  profile = var.aws_profile_gw
  region  = var.aws_region_gw_dr
  alias   = "gw-dr"
}
