provider "aws" {
  region     = var.region
}

data "template_file" "cloudinit" {
  template = file("./cloudinit.tpl")
  vars = {
    bucket              = var.bucket
    tarball_path        = var.tarball_path
  }
}

resource "random_password" "seed" {
  length           = 5
  special          = false  
}

resource "aws_iam_instance_profile" "dsf_hub_instance_iam_profile" {
  name = "dsf_hub_instance_iam_profile_${random_password.seed.result}"
  role = "${aws_iam_role.dsf_hub_role.name}"
}

resource "aws_iam_role" "dsf_hub_role" {
  name = "imperva_dsf_hub_role-${random_password.seed.result}"
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonS3FullAccess"]
  assume_role_policy = jsonencode({
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

resource "aws_instance" "dsf_base_instance" {
  ami                           = var.rhel79_amis_ids[var.region]
  instance_type                 = var.instance_type
  key_name                      = var.key_pair
  subnet_id                     = var.subnet_id
  user_data                     = data.template_file.cloudinit.rendered
  iam_instance_profile          = aws_iam_instance_profile.dsf_hub_instance_iam_profile.id
  root_block_device {
    volume_size                   = 60
  }
  tags = {
    Name = "Helper ec2 to create ami"
  }
  disable_api_termination = true
}
