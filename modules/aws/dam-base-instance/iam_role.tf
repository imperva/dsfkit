#################################
# DSF node IAM role
#################################

locals {
  instance_profile = var.instance_profile_name == null ? aws_iam_instance_profile.dsf_node_instance_iam_profile[0].name : var.instance_profile_name
  role_arn  = var.instance_profile_name == null ? aws_iam_role.dsf_node_role[0].arn : data.aws_iam_instance_profile.profile[0].role_arn
  role_name = var.instance_profile_name == null ? aws_iam_role.dsf_node_role[0].name : data.aws_iam_instance_profile.profile[0].role_name

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
  inline_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : var.iam_actions,
        "Resource" : "*"
      },
    ]
  })
  inline_policy_kms = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt"
        ],
        "Resource" : "${aws_kms_key.password_kms.arn}"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "dsf_node_instance_iam_profile" {
  count       = var.instance_profile_name == null ? 1 : 0
  name_prefix = "${var.name}-${var.resource_type}-instance-iam-profile"
  role        = local.role_name
  tags = var.tags
}

resource "aws_iam_role" "dsf_node_role" {
  count               = var.instance_profile_name == null ? 1 : 0
  description         = "${var.name}-${var.resource_type}-role-${var.name}"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "${var.name}-dam-base"
    policy = local.inline_policy
  }
  inline_policy {
    name   = "${var.name}-kms-decrypt-access"
    policy = local.inline_policy_kms
  }
  tags = var.tags
}
data "aws_iam_instance_profile" "profile" {
  count = var.instance_profile_name != null ? 1 : 0
  name = var.instance_profile_name
}
