

locals {
  db_username = "admin"
}

resource "random_password" "admin_password" {
  length           = 15
  special          = false
}

resource "random_pet" "pet" {
  separator = "_"
}

#################################
# Provision db
#################################
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  db_name              = "db_demo_${random_pet.pet.id}"
  identifier           = "edsf-db-demo"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = local.db_username
  password             = random_password.admin_password.result
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

data "template_file" "onboarder" {
  template = file("${path.module}/onboarder.tpl")
  vars = {
    dsf_hub_address     = var.hub_address
    ssh_key_path        = var.hub_ssh_key_path
    assignee_gw         = var.assignee_gw
    db_user             = local.db_username
    db_password         = random_password.admin_password.result
    db_arn              = aws_db_instance.default.arn
    module_path         = path.module
  }
}

resource "null_resource" "onboarder" {
  provisioner "local-exec" {
    command         = "${data.template_file.onboarder.rendered}"
    interpreter     = ["/bin/bash", "-c"]
  }
  depends_on = [
    aws_db_instance.default
  ]
}
