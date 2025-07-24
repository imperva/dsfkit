locals {
  ami_default = {
    id               = null
    owner_account_id = "679593333241" // aws marketplace
    name_regex       = "k170v-${var.ciphertrust_manager_version}.*"
    product_code     = "a5j8w8j2tn9crtnai795fkf6o"
  }

  ami = var.ami != null ? var.ami : local.ami_default

  ami_owner        = local.ami.owner_account_id != null ? local.ami.owner_account_id : "self"
  ami_name_regex   = local.ami.name_regex != null ? local.ami.name_regex : ".*"
  ami_product_code = local.ami.product_code != null ? local.ami.product_code : "*"

  ami_id = local.ami.id != null ? local.ami.id : (length(data.aws_ami.selected-ami) > 0 ? data.aws_ami.selected-ami[0].image_id : null)
}

data "aws_ami" "selected-ami" {
  count       = local.ami.id != null ? 0 : 1
  most_recent = true
  name_regex  = local.ami_name_regex

  filter {
    name   = "product-code"
    values = [local.ami_product_code]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = [local.ami_owner]
}