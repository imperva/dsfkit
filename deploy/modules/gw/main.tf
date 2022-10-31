

#################################
# Hub IAM role
#################################

locals {
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
          "arn:aws:s3:::${var.tarball_bucket_name}",
          "arn:aws:s3:::${var.tarball_bucket_name}/*",
        ]
      }
    ]
    }
  )
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

resource "random_string" "gw_id" {
  length  = 8
  special = false
}

resource "aws_iam_instance_profile" "dsf_gw_instance_iam_profile" {
  name_prefix = "dsf-hub-instance-iam-profile"
  role        = aws_iam_role.dsf_gw_role.name
}

resource "aws_iam_role" "dsf_gw_role" {
  name_prefix         = "imperva-dsf-gw-role"
  description         = "imperva-dsf-gw-role-${var.name}-${random_string.gw_id.result}"
  managed_policy_arns = null
  inline_policy {
    name   = "imperva-dsf-s3-access"
    policy = local.inline_policy_s3
  }
  assume_role_policy = local.role_assume_role_policy
}

module "gw_instance" {
  source              = "../../modules/sonar_base_instance"
  name                = var.name
  subnet_id           = var.subnet_id
  key_pair            = var.key_pair
  ec2_instance_type   = var.instance_type
  ebs_state_disk_size = var.disk_size
  sg_ingress_cidr     = var.sg_ingress_cidr
  #  sg_ingress_sg         = var.sg_ingress_hub
  public_ip               = var.public_ip
  iam_instance_profile_id = aws_iam_instance_profile.dsf_gw_instance_iam_profile.name
}
