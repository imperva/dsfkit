#################################
# Hub IAM role
#################################

locals {
  role_arn  = var.role_arn != null ? var.role_arn : aws_iam_role.dsf_hub_role[0].arn
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
}

resource "aws_iam_instance_profile" "dsf_hub_instance_iam_profile" {
  name_prefix = "dsf-hub-instance-iam-profile"
  role        = local.role_name
}

resource "aws_iam_role" "dsf_hub_role" {
  count               = var.role_arn != null ? 0 : 1
  name_prefix         = "imperva-dsf-hub-role"
  description         = "imperva-dsf-hub-role-${var.name}"
  managed_policy_arns = null
  assume_role_policy  = local.role_assume_role_policy
}
