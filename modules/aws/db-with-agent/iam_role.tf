#################################
# DSF node IAM role
#################################

locals {
  role_arn  = aws_iam_role.dsf_node_role.arn
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
  inline_policy_s3 = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "getFileFromS3BucketPrefix",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject"
        ]
        "Resource" : [
          "arn:aws:s3:::${local.installation_s3_bucket_and_prefix}/*",
        ]
      }
    ]
    }
  )
}

resource "aws_iam_instance_profile" "dsf_node_instance_iam_profile" {
  name_prefix = join("-", [var.friendly_name, "agent", "instance-iam-profile"])
  role        = local.role_name
  tags        = var.tags
}

resource "aws_iam_role" "dsf_node_role" {
  # name_prefix         = join("-", [var.friendly_name, "agent", "role"])
  description         = join("-", [var.friendly_name, "agent", "role"])
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "${var.friendly_name}-s3-access"
    policy = local.inline_policy_s3
  }
  tags = var.tags
}
