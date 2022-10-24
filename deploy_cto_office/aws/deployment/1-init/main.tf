terraform {
  required_version = ">= 0.12.8"
}

provider "aws" {
  region = var.region
}

#################################
# Generating system passwords
#################################

# Uncomment this section to use randomly generated passwords
# /* Populate AWS secrets */
# resource "random_password" "admin_password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "secadmin_password" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "sonarg_pasword" {
#   length = 13
#   special = true
#   override_special = "#"
# }

# /* Populate AWS secrets */
# resource "random_password" "sonargd_pasword" {
#   length = 13
#   special = true
#   override_special = "#"
# }

locals {
  # Uncomment this section to use randomly generated passwords instead of the pre-defined passwords listedbelow
  # dsf_passwords_obj  = {
  #   admin_password = random_password.admin_password.result
  #   secadmin_password = random_password.secadmin_password.result
  #   sonarg_pasword = random_password.sonarg_pasword.result
  #   sonargd_pasword = random_password.sonargd_pasword.result
  # }
  dsf_passwords_obj  = {
    admin_password = var.default_password
    secadmin_password = var.default_password
    sonarg_pasword = var.default_password
    sonargd_pasword = var.default_password
  }
}

resource "aws_secretsmanager_secret" "dsf_passwords" {
  name = "${var.environment}/dsf_passwords"
}

resource "aws_secretsmanager_secret_version" "dsf_passwords" {
  secret_id     = aws_secretsmanager_secret.dsf_passwords.id
  secret_string = jsonencode(local.dsf_passwords_obj)
}

####################################################
# Generating separate ssh federation keys for Hub and Gateway
####################################################

resource "tls_private_key" "dsf_hub_ssh_federation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_public_key" {
  name          = "${var.environment}/dsf_hub_federation_public_key"
  description   = "Imperva DSF Hub sonarw public ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_public_key_ver" {
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_public_key.id
  secret_string = resource.tls_private_key.dsf_hub_ssh_federation_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "dsf_hub_federation_private_key" {
  name          = "${var.environment}/dsf_hub_federation_private_key"
  description   = "Imperva DSF Hub sonarw private ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_hub_federation_private_key_ver" {
  secret_id     = aws_secretsmanager_secret.dsf_hub_federation_private_key.id
  secret_string = resource.tls_private_key.dsf_hub_ssh_federation_key.private_key_pem
}

resource "tls_private_key" "dsf_gateway_ssh_federation_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_secretsmanager_secret" "dsf_gateway_federation_public_key" {
  name          = "${var.environment}/dsf_gateway_federation_public_key"
  description   = "Imperva DSF Gateway sonarw public ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_gateway_federation_public_key_ver" {
  secret_id     = aws_secretsmanager_secret.dsf_gateway_federation_public_key.id
  secret_string = resource.tls_private_key.dsf_gateway_ssh_federation_key.public_key_openssh
}

resource "aws_secretsmanager_secret" "dsf_gateway_federation_private_key" {
  name          = "${var.environment}/dsf_gateway_federation_private_key"
  description   = "Imperva DSF Gateway sonarw private ssh key - used for remote gw federation"
}

resource "aws_secretsmanager_secret_version" "dsf_gateway_federation_private_key_ver" {
  secret_id     = aws_secretsmanager_secret.dsf_gateway_federation_private_key.id
  secret_string = resource.tls_private_key.dsf_gateway_ssh_federation_key.private_key_pem
}

###############################################
# Hub IAM role to read from aws secrets manager
###############################################

resource "aws_iam_instance_profile" "dsf_instance_iam_profile" {
  name = "${var.environment}_dsf_instance_iam_profile"
  role = "${aws_iam_role.dsf_role.name}"
}

resource "aws_iam_role" "dsf_role" {
  name = "${var.environment}_imperva_dsf_role"
  managed_policy_arns = null
  inline_policy {
    name = "imperva_dsf_access"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
            "s3:ListAllMyBuckets",
            "redshift:DescribeClusters",
            "s3:ListBucket"
          ],
          "Resource": "*"
        },
        {
          "Sid": "VisualEditor1",
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "sts:AssumeRole",
            "secretsmanager:GetSecretValue",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:GetLogEvents",
            "s3:ListBucket",
            "logs:FilterLogEvents",
            "rds:DescribeDBClusters",
            "rds:DescribeOptionGroups",
            "rds:DescribeDBInstances",
          ],
          "Resource": [
            "${aws_secretsmanager_secret.dsf_hub_federation_public_key.arn}",
            "${aws_secretsmanager_secret.dsf_hub_federation_private_key.arn}",
            "${aws_secretsmanager_secret.dsf_gateway_federation_public_key.arn}",
            "${aws_secretsmanager_secret.dsf_gateway_federation_private_key.arn}",
            "arn:aws:logs:us-east-2:658749227924:log-group:*:log-stream:*",
            "arn:aws:logs:*:*:log-group:/aws/rds/*:log-stream:*",
            "arn:aws:s3:::${var.s3_bucket}",
            "arn:aws:s3:::${var.s3_bucket}/*",
            "arn:aws:rds:*:658749227924:db:*",
            "arn:aws:rds:*:658749227924:og:*",
            "arn:aws:rds:*:658749227924:cluster:*",
            "arn:aws:iam::658749227924:role/${var.environment}_imperva_dsf_role"
          ]
        }
      ]
    })
  }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = "AllowAssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}