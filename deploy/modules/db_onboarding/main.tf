locals {
  db_username = "admin"
}

resource "random_password" "db_password" {
  length           = 15
  special          = false
}

resource "random_pet" "db_name" {
  separator = "_"
}

resource "random_pet" "db_id" {
}

#################################
# Provision db
#################################
resource "aws_db_instance" "default" {
  allocated_storage    = 20
  db_name              = "db_demo_${random_pet.db_name.id}"
  identifier           = "edsf-db-demo-${random_pet.db_id.id}"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  username             = local.db_username
  password             = random_password.db_password.result
  parameter_group_name = "default.mysql5.7"
  publicly_accessible  = true
  skip_final_snapshot  = true
  backup_retention_period = 0
  lifecycle {
    ignore_changes = [
      enabled_cloudwatch_logs_exports
    ]
  }
}

data "aws_iam_role" "assignee_role" {
  name = split("/", var.assignee_role)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_iam_policy" "db_cloudwatch_policy" {
  description = "Cloudwatch read policy for collecting audit from ${aws_db_instance.default.arn}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:Describe*",
        "logs:Get*",
        "logs:List*",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:TestMetricFilter",
        "logs:FilterLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "test-attach" {
  name       = "collect-audit-attachment"
  roles      = [data.aws_iam_role.assignee_role.name]
  policy_arn = aws_iam_policy.db_cloudwatch_policy.arn
}

data "template_file" "onboarder" {
  template = file("${path.module}/onboarder.tpl")
  vars = {
    dsf_hub_address     = var.hub_address
    ssh_key_path        = var.hub_ssh_key_path
    assignee_gw         = var.assignee_gw
    db_user             = local.db_username
    db_password         = random_password.db_password.result
    db_arn              = aws_db_instance.default.arn
    module_path         = path.module
    hub_role_arn        = var.assignee_role
  }
}

resource "null_resource" "onboarder" {
  provisioner "local-exec" {
    command         = "${data.template_file.onboarder.rendered}"
    interpreter     = ["/bin/bash", "-c"]
  }
  triggers = {
    db_arn = aws_db_instance.default.arn
  }
}
