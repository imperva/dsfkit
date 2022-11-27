#################################
# Generating ssh federation keys
#################################

resource "tls_private_key" "dsf_hub_ssh_federation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  dsf_hub_ssh_federation_key = !var.hadr_secondary_node ? "${chomp(resource.tls_private_key.dsf_hub_ssh_federation_key.public_key_openssh)} produced-by-terraform" : var.hadr_main_sonarw_public_key
  created_secret_aws_arn     = length(resource.aws_secretsmanager_secret.dsf_hub_federation_private_key) > 0 ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].arn : ""
  created_secret_aws_name    = length(resource.aws_secretsmanager_secret.dsf_hub_federation_private_key) > 0 ? resource.aws_secretsmanager_secret.dsf_hub_federation_private_key[0].name : ""
  secret_aws_arn             = !var.hadr_secondary_node ? local.created_secret_aws_arn : var.hadr_main_hub_sonarw_secret.arn
  secret_aws_name            = !var.hadr_secondary_node ? local.created_secret_aws_name : var.hadr_main_hub_sonarw_secret.name
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_public_key" {
  count       = !var.hadr_secondary_node ? 1 : 0
  name_prefix = "dsf-hub-federation-public-key"
  description = "Imperva DSF Hub sonarw public ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_public_key_ver" {
  count         = !var.hadr_secondary_node ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_public_key[0].id
  secret_string = chomp(local.dsf_hub_ssh_federation_key)
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_private_key" {
  count       = !var.hadr_secondary_node ? 1 : 0
  name_prefix = "dsf-hub-federation-private-key"
  description = "Imperva DSF Hub sonarw private ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_private_key_ver" {
  count         = !var.hadr_secondary_node ? 1 : 0
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_private_key[0].id
  secret_string = resource.tls_private_key.dsf_hub_ssh_federation_key.private_key_pem
}

#################################
# Hub IAM role
#################################

locals {
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

resource "aws_iam_instance_profile" "dsf_hub_instance_iam_profile" {
  name_prefix = "dsf-hub-instance-iam-profile"
  role        = aws_iam_role.dsf_hub_role.name
}

resource "aws_iam_role" "dsf_hub_role" {
  name_prefix         = "imperva-dsf-hub-role"
  description         = "imperva-dsf-hub-role-${var.name}"
  managed_policy_arns = null
  inline_policy {
    name   = "imperva-dsf-secret-access"
    policy = local.inline_policy_secret
  }
  inline_policy {
    name   = "imperva-dsf-s3-access"
    policy = local.inline_policy_s3
  }
  assume_role_policy = local.role_assume_role_policy
}

#################################
# Actual Hub instance
#################################

module "hub_instance" {
  source                        = "../../modules/sonar-base-instance"
  resource_type                 = "hub"
  name                          = var.name
  subnet_id                     = var.subnet_id
  key_pair                      = var.key_pair
  ec2_instance_type             = var.instance_type
  ebs_values = {
    disk_size = var.disk_size
    provisioned_iops = var.ebs_provisioned_iops
    throughput = var.ebs_througput
  }
  dsf_base_ami_name_tag         = var.dsf_base_ami_name_tag
  web_console_sg_ingress_cidr   = var.web_console_sg_ingress_cidr
  sg_ingress_cidr               = var.sg_ingress_cidr
  public_ip                     = true
  iam_instance_profile_id       = aws_iam_instance_profile.dsf_hub_instance_iam_profile.id
  additional_install_parameters = var.additional_install_parameters
  admin_password                = var.admin_password
  ssh_key_pair_path             = var.ssh_key_pair_path
  installation_location         = var.installation_location
  sonarw_public_key             = local.dsf_hub_ssh_federation_key
  sonarw_secret_name            = local.secret_aws_name
}