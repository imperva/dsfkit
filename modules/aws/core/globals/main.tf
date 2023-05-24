locals {
  tarball_s3_key_map = {
    "4.11"     = "jsonar-4.11.0.0.0.tar.gz"
    "4.10.0.1" = "jsonar-4.10.0.1.0.tar.gz"
    "4.10"     = "jsonar-4.10.0.0.0.tar.gz"
    "4.9"      = "jsonar-4.9.c_20221129220420.tar.gz"
  }
  supported_versions = keys(local.tarball_s3_key_map)
  s3_object          = var.tarball_s3_key != null ? var.tarball_s3_key : local.tarball_s3_key_map[var.sonar_version]
  s3_object_version  = regex("\\d\\.\\d*", local.s3_object)
}

resource "random_id" "salt" {
  byte_length = 2
}

resource "null_resource" "postpone_data_to_apply_phase" {
  triggers = {
    always_run = timestamp()
  }
}

data "http" "workstation_public_ip" {
  url = "http://ipv4.icanhazip.com"
  depends_on = [
    null_resource.postpone_data_to_apply_phase
  ]
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" { state = "available" }

resource "time_static" "current_time" {}

resource "random_password" "pass" {
  length           = 14
  special          = true
  numeric          = true
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  override_special = "*+=#%^:/~.,[]_"
}