#################################
# DSF DAM node IAM role
#################################

locals {
  role_arn  = var.role_arn != null ? var.role_arn : try(aws_iam_role.dsf_node_role[0].arn, null)
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
  name_prefix = "dsf-${var.resource_type}-instance-iam-profile"
  role        = local.role_name
}

resource "aws_iam_role" "dsf_node_role" {
  count               = var.role_arn != null ? 0 : 1
  name_prefix         = "imperva-dsf-${var.resource_type}-role"
  description         = "imperva-dsf-${var.resource_type}-role-${var.name}"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
  inline_policy {
    name   = "imperva-dsf-dam-base"
    policy = local.inline_policy
  }
  inline_policy {
    name   = "imperva-dsf-kms-decrypt-access"
    policy = local.inline_policy_kms
  }
}
