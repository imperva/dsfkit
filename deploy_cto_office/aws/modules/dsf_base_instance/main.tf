########################################################
################ DSF Instance Configs ##################
########################################################

locals {
  ebs_disk_type   = "gp3"
  ebs_iops        = 16000
  ebs_throughput  = 1000
}

resource "aws_eip" "dsf_instance_eip" {
  instance = aws_instance.dsf_base_instance.id
  vpc      = true
}

data "aws_region" "current" {}

data "aws_ami" "redhat-7-ami" {
  most_recent = true
  owners      = ["309956199498"] # Amazon

  filter {
    name   = "name"
    values = ["RHEL-7.9*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "dsf_base_instance" {
  ami                           = data.aws_ami.redhat-7-ami.image_id
  instance_type                 = var.ec2_instance_type
  key_name                      = var.key_pair
  subnet_id                     = var.subnet_id
  user_data                     = var.ec2_user_data
  iam_instance_profile          = var.dsf_iam_profile_name
  vpc_security_group_ids        = [aws_security_group.public.id]
  tags = {
    Name = var.name
  }
  disable_api_termination = true
}

# Attach an additional storage device to DSF base instance
data "aws_subnet" "selected_subnet" {
  id = var.subnet_id
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdb"
  volume_id   = aws_ebs_volume.ebs_vol.id
  instance_id = aws_instance.dsf_base_instance.id
  stop_instance_before_detaching = true
}

resource "aws_ebs_volume" "ebs_vol" {
  size              = var.ebs_disk_size
  type              = local.ebs_disk_type
  iops              = local.ebs_iops
  throughput        = local.ebs_throughput
  availability_zone = data.aws_subnet.selected_subnet.availability_zone
  tags = {
    Name = "${var.name}-ebs-volume"
  }
}

########################################################
#############  DSF Security Group Configs ##############
########################################################

data "aws_subnet" "subnet" {
  id = var.subnet_id
}

resource "aws_security_group" "public" {
  description = "Public internet access"
  vpc_id      = data.aws_subnet.subnet.vpc_id

  tags = {
    Name = join("-", [var.name, "sg"])
  }
}

resource "aws_security_group_rule" "public_out" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_in_http2" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_in_https2" {
  type              = "ingress"
  from_port         = 8443
  to_port           = 8443
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "sonarrsyslog" {
  type              = "ingress"
  from_port         = 10800
  to_port           = 10899
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.public.id
}

#resource "aws_security_group_rule" "public_all" {
#  type              = "ingress"
#  from_port         = 0
#  to_port           = 65000
#  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.public.id
#}
