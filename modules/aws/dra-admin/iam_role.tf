#################################
# DSF node IAM role
#################################

locals {
  instance_profile = var.instance_profile_name == null ? aws_iam_instance_profile.dsf_node_instance_iam_profile[0].name : var.instance_profile_name
  role_arn         = var.instance_profile_name == null ? aws_iam_role.dsf_node_role[0].arn : data.aws_iam_instance_profile.profile[0].role_arn
  role_name        = var.instance_profile_name == null ? aws_iam_role.dsf_node_role[0].name : data.aws_iam_instance_profile.profile[0].role_name

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
          aws_secretsmanager_secret.admin_analytics_registration_password.arn,
          aws_secretsmanager_secret.admin_password.arn,
        ]
      }
    ]
    }
  )
}

resource "aws_iam_instance_profile" "dsf_node_instance_iam_profile" {
  count       = var.instance_profile_name == null ? 1 : 0
  name_prefix = "${var.friendly_name}-dra-admin-instance-iam-profile"
  role        = local.role_name
  tags        = var.tags
}

resource "aws_iam_role" "dsf_node_role" {
  count               = var.instance_profile_name == null ? 1 : 0
  name                = "${var.friendly_name}-role"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-dra-admin-secret-access"
    policy = local.inline_policy_secret
  }
  tags = var.tags
}
data "aws_iam_instance_profile" "profile" {
  count = var.instance_profile_name != null ? 1 : 0
  name  = var.instance_profile_name
}
