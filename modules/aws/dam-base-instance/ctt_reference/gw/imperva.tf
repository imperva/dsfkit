
terraform {

    required_providers {
        aws = ">= 2.55.0"
    }
}


variable "ImpervaVariables" {
  default = {
    General = {
      Products = " damgwbyol"
      VolumeSize = "500"
    }
    SSH = {
      UserName = "ec2-user"
    }
  }
}

variable "damgwbyolRegion2Ami" {
  default = {
    af-south-1 = {
      ImageId = "ami-079e3d30c3074147d"
    }
    ap-east-1 = {
      ImageId = "ami-03ac6c9504dc26ac2"
    }
    ap-northeast-1 = {
      ImageId = "ami-001c5dba9b08e1e20"
    }
    ap-northeast-2 = {
      ImageId = "ami-08b9cdffbc03dee8b"
    }
    ap-northeast-3 = {
      ImageId = "ami-0f1e40e7e8e549a58"
    }
    ap-south-1 = {
      ImageId = "ami-02c40d18eb669ff26"
    }
    ap-southeast-1 = {
      ImageId = "ami-06e7bef08cdc49198"
    }
    ap-southeast-2 = {
      ImageId = "ami-05ef3406d6e34b6da"
    }
    ca-central-1 = {
      ImageId = "ami-053e90b658d30bc99"
    }
    eu-central-1 = {
      ImageId = "ami-0b89ffcd9a860992b"
    }
    eu-north-1 = {
      ImageId = "ami-0329f6538d2e8180d"
    }
    eu-west-1 = {
      ImageId = "ami-0490ed56f9a4fbc77"
    }
    eu-west-2 = {
      ImageId = "ami-0f2c96ca38d80ff73"
    }
    eu-west-3 = {
      ImageId = "ami-0c6a9375caa74fa76"
    }
    sa-east-1 = {
      ImageId = "ami-0bc7e775cb2d5ec2f"
    }
    us-east-1 = {
      ImageId = "ami-019af5343736a400e"
    }
    us-east-2 = {
      ImageId = "ami-046e98684e13345cd"
    }
    us-gov-east-1 = {
      ImageId = "ami-0220487b63f39463d"
    }
    us-gov-west-1 = {
      ImageId = "ami-036febe3bded78c9a"
    }
    us-west-1 = {
      ImageId = "ami-060d440817f97f6a5"
    }
    us-west-2 = {
      ImageId = "ami-0d3d795b13aa624f9"
    }
  }
}

variable "GatewayModel2InstanceType" {
  default = {
    AV2500 = {
      InstanceType = "m4.xlarge"
    }
    AV6500 = {
      InstanceType = "r4.2xlarge"
    }
  }
}

variable "region" {
  type = string
  description = "The region to deploy on"
  default = "us-east-1"
}

variable "keyPairName" {
  type = string
  description = "Select name of an existing EC2 Key Pair to enable SSH access to the instances"
}

variable "vpc" {
  type = string
  description = "Select the Virtual Private Cloud (VPC) Id for the SecureSphere stack"
}

variable "securePassword" {
  type = string
  description = "Enter the Secure application password (GW->MX registration)"
}

variable "timezone" {
  type = string
  description = "Enter Timezone string using the Posix TZ format. If you enter	\"default\", the Amazon default (GMT) is used"
  default = "UTC"
}

variable "gwSubnet" {
  type = string
  description = "Select Subnet"
}

variable "agentListenerPort" {
  type = number
  description = "Enter listener\"s port number."
  default = 8030
}

variable "agentListenerSsl" {
  type = string
  description = "This option may increase CPU consumption on the Agent host. Do you wish to enable SSL?"
  default = "False"
}

variable "numberOfGateways" {
  type = number
  description = "Choose the number of Gateway instances (1-50)"
  default = 1
}

variable "gwModel" {
  type = string
  description = "Enter the Gateway Model"
  default = "AV2500"
}

variable "managementServerHost" {
  type = string
  description = "Enter Management Server\"s Hostname or IP address"
  default = "123.123.123.123"
}

data "aws_caller_identity" "current" {
}

locals {
    uniqueName = uuid()
    UserName = "UserName"
    port = "port"
    comma = ","
    colon = ":"
    empty = ""
    URL = "URL"
    USER = "USER"
    PASSWORD = "PASSWORD"
    configureLB = "configureLB"
    interval = "interval"
    https = "https"
    timeout = "timeout"
    healthyThreshold = "healthyThreshold"
    unhealthyThreshold = "unhealthyThreshold"
    UseSingleGWGroup = "UseSingleGWGroup"
    LBHealthCheck = "LBHealthCheck"
    HealthCheckPort = "HealthCheckPort"
    SSH = "SSH"
    VPC = "VPC"
    AMI = "AMI"
    CIDR = "CIDR"
    PublicA = "PublicA"
    PublicB = "PublicB"
    MGMTA = "MGMTA"
    MGMTB = "MGMTB"
    DataA = "DataA"
    DataB = "DataB"
    AV1000 = "AV1000"
    AV2500 = "AV2500"
    AV4500 = "AV4500"
    AV6500 = "AV6500"
    General = "General"
    Throughput = "Throughput"
    scaleName = "gw_autoscaling_group_%s"
    VolumeSize = "VolumeSize"
    InstanceType = "InstanceType"
}

provider "aws" {
  region = var.region
}

data "aws_vpc" "vpc" {
  id = "${var.vpc}"
}

resource "aws_kms_key" "securePasswordEncrypted" {
  description = "Secure password"
  deletion_window_in_days = 10
}

data "aws_kms_ciphertext" "encryptedPassword" {
  key_id = aws_kms_key.securePasswordEncrypted.key_id
  plaintext = var.securePassword
  depends_on = [aws_kms_key.securePasswordEncrypted]
}

resource "aws_iam_policy" "kms_policy_securePasswordEncrypted" {
  name = "kms_policy_securePasswordEncrypted_${local.uniqueName}"
  description = "A policy to allow KMS decryption"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
								"kms:Decrypt"
                ],
            "Resource": "${aws_kms_key.securePasswordEncrypted.arn}"
        }
    ]
}
EOF
}

locals {
    securePassword = chomp(data.aws_kms_ciphertext.encryptedPassword.ciphertext_blob)
}

resource "aws_iam_policy" "Gw_role_policy" {
  name = "Gw_role_policy_${local.uniqueName}"
  description = "A policy to allow GW actions"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
								"ec2:DescribeSecurityGroups",
								"elasticloadbalancing:DescribeLoadBalancers",
								"ec2:DescribeInstanceAttribute",
								"ec2:ModifyInstanceAttribute",
								"rds:DescribeDBLogFiles",
								"rds:DownloadCompleteDBLogFile",
								"rds:DownloadDBLogFilePortion",
								"s3:PutObject",
								"s3:PutObjectAcl",
								"s3:PutObjectTagging",
								"s3:PutObjectVersionAcl",
								"s3:PutObjectVersionTagging",
								"ec2:DescribeInstances"
                ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
								"cloudformation:DescribeStackResource",
								"cloudformation:DescribeStackResources",
								"cloudformation:DescribeStacks"
                ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
								"ec2:AuthorizeSecurityGroupIngress"
                ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "role_attach_Gw_role_policy_Gw" {
  name = "role_attach_Gw_role_policy_ ${local.uniqueName}"
  roles = [aws_iam_role.GwRootRole.name]
  policy_arn = aws_iam_policy.Gw_role_policy.arn
}

resource "aws_iam_role" "GwRootRole" {
  name = "GwRootRole${local.uniqueName}"
  path = "/"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service":"ec2.amazonaws.com"
            }
        }
     ]
}
EOF
}

resource "aws_iam_instance_profile" "GwRootInstanceProfile" {
  name = "GwRootInstanceProfile_${local.uniqueName}"
  role = aws_iam_role.GwRootRole.name
}

resource "aws_iam_policy_attachment" "role_attach_kms_policy_securePasswordEncrypted_Gw" {
  name = "role_attach_kms_policy_securePasswordEncrypted_ ${local.uniqueName}"
  roles = [aws_iam_role.GwRootRole.name]
  policy_arn = aws_iam_policy.kms_policy_securePasswordEncrypted.arn
}

resource "aws_security_group" "aws_security_group_gw" {
  name = "aws_security_group_gw_${local.uniqueName}"
  description = "Enable inbound traffic access to GW"
  vpc_id = data.aws_vpc.vpc.id

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["172.16.0.0/12"]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 3792
      to_port = 3792
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 3792
      to_port = 3792
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 7700
      to_port = 7700
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = var.agentListenerPort
      to_port = var.agentListenerPort
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ami_damgwbyol" {
  owners = ["aws-marketplace"]

  filter {
      name = "image-id"
      values = [lookup(var.damgwbyolRegion2Ami[var.region],"ImageId")]
  }
}

resource "aws_launch_configuration" "gw_damgwbyol" {
  name = "gw_${local.uniqueName}"
  image_id = data.aws_ami.ami_damgwbyol.id
  instance_type = lookup(var.GatewayModel2InstanceType[var.gwModel],local.InstanceType)
  key_name = var.keyPairName
  user_data = "WaitHandle : none\nStackId : none\nRegion : ${var.region}\nProductLicensing :  BYOL\nIsTerraform : true\nSecurePassword : ${local.securePassword}\nKMSKeyRegion : ${var.region}\nRegistrationParams : {\"StackName\" : \"${local.uniqueName}\",\"StackId\" : \"${local.uniqueName}\",\"SQSName\" : \"\",\"Region\" : \"${var.region}\",\"AccessKey\" : \"\",\"SecretKey\" : \"\"}\nProductRole :  gateway\nAssetTag : ${var.gwModel}\nGatewayMode :  dam\nMetaData : {\"commands\": [\"/opt/SecureSphere/etc/ec2/create_audit_volume --volumesize=${lookup(var.ImpervaVariables[local.General],local.VolumeSize)}\", \"/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${lookup(var.ImpervaVariables[local.SSH],local.UserName)} --gateway_group=${local.uniqueName} --secure_password=%securePassword% --imperva_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_server_ip=${var.managementServerHost} --management_interface=eth0 --internal_data_interface=eth0 --external_data_interface=eth0 --check_server_status --check_gateway_received_configuration --register --initiate_services --set_sniffing --listener_port=${var.agentListenerPort} --agent_listener_ssl=${var.agentListenerSsl} --cluster-enabled --cluster-port=3792 --product=DAM\"]}\n"
  iam_instance_profile = aws_iam_instance_profile.GwRootInstanceProfile.name
  security_groups = [aws_security_group.aws_security_group_gw.id]
}

output "cloudFormUrl" {
  value = "https://cloud-template-tool-data-security.imperva.com/?products=damgwbyol&keyPairMode=Provide%20Later&gwGroupNameOverride=False&gwModel=AV2500&managementServerHost=123.123.123.123&LargeScaleGatewayMode=False&numberOfGateways=1&agentListenerPort=8030&agentListenerSsl=False&internetMethod=NAT&dnsConfMethod=DHCP&NetworkConfigMode=Provide%20Later&timezone=UTC&setNtp=False"
}

output "UniqueName" {
  value = local.uniqueName
}
