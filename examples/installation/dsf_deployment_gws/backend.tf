terraform {
  backend "s3" {
#   Fill in your bucket details
    bucket  = "tf-state"
    key     = "states/terraform.tfstate"
    region  = "us-east-1"
    profile = "profile2"
  }
}
