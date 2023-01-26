#################################
# SQL Server IAM role
#################################

locals {
  role_arn  = var.role_arn != null ? var.role_arn : try(aws_iam_role.lambda_mssql_infra_role[0].arn, null)
  role_name = split("/", local.role_arn)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
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
  inline_policy_rds = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "rdsPermissions",
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBInstances"
        ]
        "Resource" : "*"
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
  description         = replace("${local.db_identifier}-og-role-${var.friendly_name}", "_", "-")
  managed_policy_arns = null
  assume_role_policy  = local.rds_db_og_role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-s3-access"
    policy = local.rds_db_og_role_inline_policy_s3
  }
}

resource "aws_iam_instance_profile" "lambda_mssql_infra_instance_iam_profile" {
  name_prefix = "lambda-mssql-infra-instance-iam-profile"
  role        = local.role_name
}

resource "aws_iam_role" "lambda_mssql_infra_role" {
  count               = var.role_arn != null ? 0 : 1
  name_prefix         = "imperva-mssql-infra-role"
  description         = "imperva-mssql-infra-role-${var.friendly_name}"
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
    name   = "imperva-dsf-mssql-rds-access"
    policy = local.inline_policy_rds
  }
  inline_policy {
    name   = "imperva-dsf-mssql-ec2-access"
    policy = local.inline_policy_ec2
  }
}
