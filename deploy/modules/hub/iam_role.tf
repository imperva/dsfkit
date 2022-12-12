#################################
# Hub IAM role
#################################

locals {
  role_arn  = var.role_arn != null ? var.role_arn : try(aws_iam_role.dsf_hub_role[0].arn, null)
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
          "${local.secret_aws_arn}"
        ]
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

resource "aws_iam_instance_profile" "dsf_hub_instance_iam_profile" {
  name_prefix = "dsf-hub-instance-iam-profile"
  role        = local.role_name
}

resource "aws_iam_role" "dsf_hub_role" {
  count               = var.role_arn != null ? 0 : 1
  name_prefix         = "imperva-dsf-hub-role"
  description         = "imperva-dsf-hub-role-${var.friendly_name}"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-s3-access"
    policy = local.inline_policy_s3
  }
  inline_policy {
    name   = "imperva-dsf-secret-access"
    policy = local.inline_policy_secret
  }
}
