#################################
# DSF node IAM role
#################################

locals {
  role_arn  = var.role_arn != null ? var.role_arn : try(aws_iam_role.dsf_dra_admin_node_role[0].arn, null)
  role_name = split("/", local.role_arn)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
  role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  inline_policy_secret = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "secretsmanager:GetSecretValue",
        "Resource" : [
          "${aws_secretsmanager_secret.admin_analytics_registration_password_secret.arn}"
        ]
      }
    ]
    }
  )
}

resource "aws_iam_instance_profile" "dsf_dra_admin_instance_iam_profile" {
  name_prefix = "dsf-dra-admin-instance-iam-profile"
  role        = local.role_name
  tags        = var.tags
}

resource "aws_iam_role" "dsf_dra_admin_node_role" {
  count               = var.role_arn != null ? 0 : 1
  name_prefix         = "imperva-dsf-dra-admin-role"
  description         = "imperva-dsf-dra-admin-role-${var.friendly_name}"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-dra-admin-secret-access"
    policy = local.inline_policy_secret
  }
  tags                = var.tags
}
