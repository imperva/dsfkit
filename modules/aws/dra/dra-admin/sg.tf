data "aws_subnet" "subnet" {
  id = var.subnet_id
}

locals {
  create_security_group_count = var.security_group_id == null ? 1 : 0
}

resource "aws_security_group" "admin_instance" {
  count       = local.create_security_group_count
  vpc_id      = data.aws_subnet.subnet.vpc_id
  description = "Security Group for the Admin Server"

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 61617
    to_port     = 61617
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}
