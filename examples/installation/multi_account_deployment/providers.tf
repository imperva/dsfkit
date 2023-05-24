# must have default provider
provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_primary
}

provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_primary
  alias   = "hub-primary"
}

provider "aws" {
  profile = var.aws_profile_hub
  region  = var.aws_region_hub_secondary
  alias   = "hub-secondary"
}

provider "aws" {
  profile = var.aws_profile_gw
  region  = var.aws_region_gw_primary
  alias   = "gw-primary"
}

provider "aws" {
  profile = var.aws_profile_gw
  region  = var.aws_region_gw_secondary
  alias   = "gw-secondary"
}
