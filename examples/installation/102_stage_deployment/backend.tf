terraform {
  backend "s3" {
    bucket         = "dsfkit-terraform-stage"
    key            = "states/terraform.tfstate"
    region         = "us-east-1"
  }
}