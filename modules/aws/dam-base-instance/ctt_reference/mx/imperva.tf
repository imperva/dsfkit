
terraform {

    required_providers {
        aws = ">= 2.55.0"
    }
}


variable "ImpervaVariables" {
  default = {
    General = {
      Products = " dammxbyol"
    }
    SSH = {
      UserName = "ec2-user"
    }
    flexKey = {
      KeyValue = "NONE"
    }
  }
}

variable "dammxbyolRegion2Ami" {
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

variable "mxInstanceType" {
  type = string
  description = "Select MX Instance Type"
  default = "c5.xlarge"
}

variable "mxSubnet" {
  type = string
  description = "Select Management-Server subnet ID"
}

variable "mxLicenseInternalPassphrase" {
  type = string
  description = "MxLicensePassphrase (do not change. Internal use only)"
  default = "k36E4CQgEro5SPLjUhuuoYDGs6EQb0Wi"
}

variable "mxPassword" {
  type = string
  description = "Enter the server gui password"
}

locals {
    encryptedMXLicense = "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"
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

resource "aws_kms_key" "mxPasswordEncrypted" {
  description = "Secure password"
  deletion_window_in_days = 10
}

data "aws_kms_ciphertext" "encryptedPasswordMX" {
  key_id = aws_kms_key.mxPasswordEncrypted.key_id
  plaintext = var.mxPassword
  depends_on = [aws_kms_key.mxPasswordEncrypted]
}

resource "aws_iam_policy" "kms_policy_mxPasswordEncrypted" {
  name = "kms_policy_mxPasswordEncrypted_${local.uniqueName}"
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
            "Resource": "${aws_kms_key.mxPasswordEncrypted.arn}"
        }
    ]
}
EOF
}

locals {
    mxPassword = chomp(data.aws_kms_ciphertext.encryptedPasswordMX.ciphertext_blob)
}

data "aws_ami" "ami_dammxbyol" {
  owners = ["aws-marketplace"]

  filter {
      name = "image-id"
      values = [lookup(var.dammxbyolRegion2Ami[var.region],"ImageId")]
  }
}

resource "time_sleep" "wait_ManagementServer" {
  create_duration = "1200s"
  depends_on = [aws_instance.mx_instance_ManagementServer]
}

resource "aws_iam_policy" "Mx_role_policy" {
  name = "Mx_role_policy_${local.uniqueName}"
  description = "A policy to allow MX actions"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
								"s3:CreateBucket",
								"s3:ListBucketMultipartUploads",
								"s3:ListMultipartUploadParts",
								"s3:AbortMultipartUpload",
								"s3:GetObject",
								"s3:ListBucket",
								"s3:GetObject",
								"s3:ListBucket",
								"s3:HeadBucket",
								"s3:ListAllMyBuckets",
								"s3:PutObject",
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
								"ec2:CreateTags"
                ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "role_attach_Mx_role_policy_Mx" {
  name = "role_attach_Mx_role_policy_ ${local.uniqueName}"
  roles = [aws_iam_role.MxRootRole.name]
  policy_arn = aws_iam_policy.Mx_role_policy.arn
}

resource "aws_iam_role" "MxRootRole" {
  name = "MxRootRole${local.uniqueName}"
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

resource "aws_iam_instance_profile" "MxRootInstanceProfile" {
  name = "MxRootInstanceProfile_${local.uniqueName}"
  role = aws_iam_role.MxRootRole.name
}

resource "aws_iam_policy_attachment" "role_attach_kms_policy_securePasswordEncrypted_Mx" {
  name = "role_attach_kms_policy_securePasswordEncrypted_ ${local.uniqueName}"
  roles = [aws_iam_role.MxRootRole.name]
  policy_arn = aws_iam_policy.kms_policy_securePasswordEncrypted.arn
}

resource "aws_iam_policy_attachment" "role_attach_kms_policy_mxPasswordEncrypted_Mx" {
  name = "role_attach_kms_policy_mxPasswordEncrypted_ ${local.uniqueName}"
  roles = [aws_iam_role.MxRootRole.name]
  policy_arn = aws_iam_policy.kms_policy_mxPasswordEncrypted.arn
}

resource "aws_security_group" "aws_security_group_mx" {
  name = "aws_security_group_mx_${local.uniqueName}"
  description = "Enable inbound traffic access to MX"
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
      from_port = 2812
      to_port = 2812
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8081
      to_port = 8081
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8083
      to_port = 8083
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8084
      to_port = 8084
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 8085
      to_port = 8085
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 514
      to_port = 514
      protocol = "udp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "mx_instance_ManagementServer" {
  ami = data.aws_ami.ami_dammxbyol.id
  instance_type = var.mxInstanceType
  key_name = var.keyPairName
  user_data = "WaitHandle : none\nStackId : none\nRegion : ${var.region}\nIsTerraform : true\nSecurePassword : ${local.securePassword}\nKMSKeyRegion : ${var.region}\nProductRole :  server\nAssetTag :  AVM150\nProductLicensing :  BYOL\nMetaData : {\"commands\": [\"/opt/SecureSphere/etc/ec2/ec2_auto_ftl --init_mode  --user=${lookup(var.ImpervaVariables[local.SSH],local.UserName)} --secure_password=%securePassword% --system_password=%securePassword% --timezone=${var.timezone} --time_servers=default --dns_servers=default --dns_domain=default --management_interface=eth0 --check_server_status --initiate_services --encLic=${local.encryptedMXLicense} --passPhrase=${var.mxLicenseInternalPassphrase} --serverPassword=%mxPassword%\"]}\nMxPassword : ${local.mxPassword}\n"
  vpc_security_group_ids = [aws_security_group.aws_security_group_mx.id]
  subnet_id = var.mxSubnet
  iam_instance_profile = aws_iam_instance_profile.MxRootInstanceProfile.name
  associate_public_ip_address = false

  tags =  {
      Name = "Imperva_dammxbyol_${local.uniqueName}"
  }
}

output "cloudFormUrl" {
  value = "https://cloud-template-tool-data-security.imperva.com/?products=dammxbyol&keyPairMode=Provide%20Later&mxModel=AVM150&mxLicenseProfile=File&encryptedLicenseContent=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&setLargeScaleMx=False&mxInstanceType=c5.xlarge&internetMethod=NAT&dnsConfMethod=DHCP&publicIp=False&manualPrivateIpSet=False&NetworkConfigMode=Provide%20Later&timezone=UTC&setNtp=False&mxLicenseInternalPassphrase=PassPhrase"
}

output "UniqueName" {
  value = local.uniqueName
}

output "ManagementServerURL" {
  value = format("https://%s:8083", aws_instance.mx_instance_ManagementServer.private_ip)
}
