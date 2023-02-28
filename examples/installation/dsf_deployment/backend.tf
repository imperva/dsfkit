terraform {
  backend "s3" {
    bucket         = "tf-state"
    key            = "terraform/terraform.tfstate"
    region         = "af-south-1"
    profile        = "default"
  }
}