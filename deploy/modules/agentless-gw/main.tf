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
          "arn:aws:s3:::${var.installation_location.s3_bucket}",
          "arn:aws:s3:::${var.installation_location.s3_bucket}/*",
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
  source                        = "../../modules/sonar-base-instance"
  resource_type                 = "gw"
  name                          = var.name
  subnet_id                     = var.subnet_id
  key_pair                      = var.key_pair
  ec2_instance_type             = var.instance_type
  ebs_state_disk_size           = var.disk_size
  sg_ingress_cidr               = var.sg_ingress_cidr
  public_ip                     = var.public_ip
  iam_instance_profile_id       = aws_iam_instance_profile.dsf_gw_instance_iam_profile.name
  additional_install_parameters = var.additional_install_parameters
  admin_password                = var.admin_password
  ssh_key_pair_path             = var.ssh_key_pair_path
  installation_location         = var.installation_location
  sonarw_public_key             = var.sonarw_public_key
  sonarw_secret_name            = var.sonarw_secret_name
  proxy_address                 = var.proxy_address
}
