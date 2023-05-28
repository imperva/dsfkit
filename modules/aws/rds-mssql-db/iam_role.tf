#################################
# SQL Server IAM role
#################################

locals {
  instance_profile = var.instance_profile_name != null ? var.instance_profile_name : aws_iam_instance_profile.lambda_mssql_infra_instance_iam_profile[0].name
  role_arn         = var.instance_profile_name != null ? aws_iam_role.lambda_mssql_infra_role[0].arn : data.aws_iam_instance_profile.profile[0].role_arn
  role_name        = var.instance_profile_name != null ? aws_iam_role.lambda_mssql_infra_role[0].name : data.aws_iam_instance_profile.profile[0].role_name
  role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy_log_group = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "logGroupPermissions",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*"
      }
    ]
  })
  inline_policy_s3 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "accessS3Permissions",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        "Resource" : [
          "arn:aws:s3:::dsf-sql-scripts-bucket*",
          "arn:aws:s3:::dsf-sql-scripts-bucket*/*",
        ]
      }
    ]
  })
  inline_policy_ec2 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ec2Permissions",
        "Effect" : "Allow",
        "Action" : [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        "Resource" : "*"
      }
    ]
  })
  rds_db_og_role_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })
  rds_db_og_role_inline_policy_s3 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : "s3:ListAllMyBuckets",
        "Resource" : "*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketACL",
          "s3:GetBucketLocation"
        ],
        "Resource" : "arn:aws:s3:::${local.db_audit_bucket_name}"
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ],
        "Resource" : "arn:aws:s3:::${local.db_audit_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role" "rds_db_og_role" {
  name_prefix         = replace("${local.db_identifier}-og-role", "_", "-")
  description         = replace("${local.db_identifier}-og-role", "_", "-")
  managed_policy_arns = null
  assume_role_policy  = local.rds_db_og_role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-s3-access"
    policy = local.rds_db_og_role_inline_policy_s3
  }
  tags = var.tags
}

resource "aws_iam_instance_profile" "lambda_mssql_infra_instance_iam_profile" {
  count       = var.instance_profile_name == null ? 1 : 0
  name_prefix = "lambda-mssql-infra-instance-iam-profile"
  role        = local.role_name
  tags        = var.tags
}

resource "aws_iam_role" "lambda_mssql_infra_role" {
  count               = var.instance_profile_name == null ? 1 : 0
  name_prefix         = "imperva-mssql-infra-role"
  description         = "imperva-mssql-infra-role"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-mssql-log-group"
    policy = local.inline_policy_log_group
  }
  inline_policy {
    name   = "imperva-dsf-mssql-s3-access"
    policy = local.inline_policy_s3
  }
  inline_policy {
    name   = "imperva-dsf-mssql-ec2-access"
    policy = local.inline_policy_ec2
  }
  tags = var.tags
}
data "aws_iam_instance_profile" "profile" {
  count = var.instance_profile_name != null ? 1 : 0
  name  = var.instance_profile_name
}
