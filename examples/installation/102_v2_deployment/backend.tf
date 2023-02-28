terraform {
  backend "s3" {
    bucket         = "state-bucket"
    key            = "states/terraform.tfstate"
    region         = "af-south-1"
    profile        = "default"
  }
}