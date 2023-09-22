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
        "Resource" : concat(
          [
            "${local.sonarw_secret_aws_arn}",
            "${local.admin_password_secret_aws_arn}",
            "${local.secadmin_password_secret_aws_arn}",
            "${local.sonarg_password_secret_aws_arn}",
            "${local.sonargd_password_secret_aws_arn}",
          ],
          [
            for val in aws_secretsmanager_secret.access_tokens : val.arn
          ]
        )
      }
    ]
    }
  )
  inline_policy_s3 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        "Resource" : [
          "arn:aws:s3:::${var.binaries_location.s3_bucket}",
          "arn:aws:s3:::${var.binaries_location.s3_bucket}/*",
        ]
      }
    ]
    }
  )
}

resource "aws_iam_instance_profile" "dsf_node_instance_iam_profile" {
  count       = var.instance_profile_name == null ? 1 : 0
  name_prefix = "${var.name}-${var.resource_type}-instance-iam-profile"
  role        = local.role_name
  tags        = var.tags
}

resource "aws_iam_role" "dsf_node_role" {
  count               = var.instance_profile_name == null ? 1 : 0
  name                = "${var.name}-role"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "${var.name}-s3-access"
    policy = local.inline_policy_s3
  }
  inline_policy {
    name   = "${var.name}-secret-access"
    policy = local.inline_policy_secret
  }
  tags = var.tags
}

data "aws_iam_instance_profile" "profile" {
  count = var.instance_profile_name != null ? 1 : 0
  name  = var.instance_profile_name
}
