data "aws_region" "current" {}

locals {
  base_filters = {
    architecture = ["x86_64"]
    virtualization-type = ["hvm"]
  }
  name_filter = {
    name = ["Imperva-DRA-Analytics-${var.dra_version}_*"]
  }
  desc_filter = {
    description = ["Imperva-DRA-Analytics-${var.dra_version}_*"]
  }
  filters = merge(local.base_filters, data.aws_region.current.name == "us-east-1" ? local.desc_filter : local.name_filter)
}

data "aws_ami" "selected-ami" {
  owners = ["496834581024"]

  dynamic "filter" {
    for_each = local.filters
    content {
      name = filter.key
      values = filter.value
    }
  }
}
