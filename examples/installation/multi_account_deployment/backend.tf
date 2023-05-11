terraform {
  backend "s3" {
    # backend "local" {
    #        bucket         = "tf-state-dsfkit-github-tests"
    bucket         = "terraform-state-bucket-dsfkit-github-tests"
    key            = "states/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    #        region         = "ap-southeast-2"
    region         = "us-east-1"
  }
}