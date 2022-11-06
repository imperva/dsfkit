locals {
  db_username = "admin"
}

resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_name" {
  separator = "_"
}

resource "random_pet" "db_id" {
}

#################################
# Provision db
#################################
resource "aws_db_instance" "rds_instance" {
  allocated_storage       = 20
  db_name                 = "db_demo_${random_pet.db_name.id}"
  identifier              = "edsf-db-demo-${random_pet.db_id.id}"
  engine                  = "mysql"
  engine_version          = "5.7"
  instance_class          = "db.t3.micro"
  username                = local.db_username
  password                = random_password.db_password.result
  parameter_group_name    = "default.mysql5.7"
  publicly_accessible     = true
  skip_final_snapshot     = true
  db_subnet_group_name  = resource.aws_db_subnet_group.default.name
  backup_retention_period = 0
  lifecycle {
    ignore_changes = [
      enabled_cloudwatch_logs_exports
    ]
  }
}

resource "aws_db_subnet_group" "default" {
  name       = var.deployment_name
  subnet_ids = var.public_subnets
}

data "aws_security_group" "rds_sg" {
  id = one(aws_db_instance.rds_instance.vpc_security_group_ids)
}

resource "aws_security_group_rule" "sg_ingress_self" {
  type              = "ingress"
  from_port         = aws_db_instance.rds_instance.port
  to_port           = aws_db_instance.rds_instance.port
  protocol          = "tcp"
  cidr_blocks       = var.database_sg_ingress_cidr
  security_group_id = data.aws_security_group.rds_sg.id
}

data "aws_iam_role" "assignee_role" {
  name = split("/", var.assignee_role)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_iam_policy" "db_cloudwatch_policy" {
  description = "Cloudwatch read policy for collecting audit from ${aws_db_instance.rds_instance.arn}"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "VisualEditor0",
      "Effect": "Allow",
      "Action": [
        "logs:Describe*",
        "logs:List*",
        "rds:DescribeDBInstances",
        "logs:StartQuery",
        "logs:StopQuery",
        "logs:TestMetricFilter",
        "logs:FilterLogEvents",
        "logs:Get*"
      ],
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

resource "null_resource" "onboarder" {
  provisioner "local-exec" {
    command = templatefile("${path.module}/onboarder.tpl", {
      dsf_hub_address = var.hub_address
      ssh_key_path    = var.hub_ssh_key_path
      assignee_gw     = var.assignee_gw
      db_user         = local.db_username
      db_password     = nonsensitive(random_password.db_password.result)
      db_arn          = aws_db_instance.rds_instance.arn
      module_path     = path.module
      onboarder_jar_bucket = var.onboarder_s3_bucket
      }
    )
    interpreter = ["/bin/bash", "-c"]
  }
  triggers = {
    db_arn = aws_db_instance.rds_instance.arn
  }
}
