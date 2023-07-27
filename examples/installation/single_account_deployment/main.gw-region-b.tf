variable "GROUPB_aws_region" {
  type        = string
  description = "Aws region for a gw group (e.g us-east-2)"
}

variable "GROUPB_subnet_gw" {
  type        = string
  description = "Aws subnet id for the primary Agentless Gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "GROUPB_security_group_ids_gw" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to the readme for additional information on the deployment restrictions when running the deployment with this variable."
}

variable "GROUPB_gw_instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the Agentless Gateway. Keep empty if you wish to create a new instance profile."
}

variable "GROUPB_gw_count" {
  type        = number
  default     = 1
  description = "Number of Agentless Gateways"
}

variable "GROUPB_gw_group_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "GROUPB_gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the Agentless Gateway"
}

variable "GROUPB_web_console_admin_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the admin user password. If not set, 'web_console_admin_password' is used."
}

variable "GROUPB_gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the Agentless Gateway instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "GROUPB_gw_key_pem_details" {
  type = object({
    private_key_pem_file_path = string
    public_key_name           = string
  })
  description = "Key pem details used to ssh to the Agentless Gateway. It contains the file path of the private key and the name of the public key. Leave this variable empty if you would like us to create it."
  # default     = null

  validation {
    condition = (
      var.GROUPB_gw_key_pem_details == null ||
      try(var.GROUPB_gw_key_pem_details.private_key_pem_file_path != null && var.GROUPB_gw_key_pem_details.public_key_name != null, false)
    )
    error_message = "All fields should be specified when specifying the gw_key_pem_details variable"
  }
}

variable "GROUPB_internal_gw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the Agentless Gateway sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "GROUPB_internal_gw_public_key_file_path" {
  type        = string
  default     = null
  description = "The Agentless Gateway sonarw user public key file path - used for remote Agentless Gateway federation, HADR, etc."
}

variable "GROUPB_ami" {
  type = object({
    id               = string
    name             = string
    username         = string
    owner_account_id = string
  })
  description = <<EOF
This variable is used for selecting an AWS machine image based on various filters. It is an object type variable that includes the following fields: id, name, username, and owner_account_id.
If set to null, the recommended image will be used.
The "id" and "name" fields are used to filter the machine image by ID or name, respectively. To select all available images for a given filter, set the relevant field to "*". The "username" field is mandatory and used to specify the AMI username.
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the current account ID will be used. The latest image that matches the specified filter will be chosen.
EOF
  default     = null
}

provider "aws" {
  profile = var.aws_profile
  region  = var.GROUPB_aws_region
  alias = "GROUPB"
}

locals {
  GROUPB_should_create_gw_key_pair  = var.GROUPB_gw_key_pem_details == null ? true : false
}

##############################
# Generating ssh keys
##############################
module "GROUPB_key_pair_gw" {
  count                    = local.GROUPB_should_create_gw_key_pair ? 1 : 0
  source                   = "imperva/dsf-globals/aws//modules/key_pair"
  version                  = "1.4.6" # latest release tag
  key_name_prefix          = "imperva-dsf-gw"
  private_key_pem_filename = "ssh_keys/dsf_ssh_key-gw-${terraform.workspace}"
  tags                     = local.tags
  providers = {
    aws = aws.GROUPB
  }
}

locals {
  GROUPB_gw_private_key_pem_file_path  = var.GROUPB_gw_key_pem_details != null ? var.GROUPB_gw_key_pem_details.private_key_pem_file_path : module.GROUPB_key_pair_gw[0].private_key_file_path
  GROUPB_gw_public_key_name            = var.GROUPB_gw_key_pem_details != null ? var.GROUPB_gw_key_pem_details.public_key_name : module.GROUPB_key_pair_gw[0].key_pair.key_pair_name
}

data "aws_subnet" "GROUPB_subnet_gw" {
  id = var.GROUPB_subnet_gw
  provider = aws.GROUPB
}

##############################
# Generating deployment
##############################
module "GROUPB_agentless_gw_group" {
  count                                  = var.GROUPB_gw_count
  source                                 = "../../../modules/aws/agentless-gw"
  friendly_name                          = join("-", [local.deployment_name_salted, "b", "gw", count.index])
  subnet_id                              = var.GROUPB_subnet_gw
  security_group_ids                     = var.GROUPB_security_group_ids_gw
  instance_type                          = var.GROUPB_gw_instance_type
  ebs                                    = var.GROUPB_gw_group_ebs_details
  binaries_location                      = local.tarball_location
  web_console_admin_password             = local.web_console_admin_password
  web_console_admin_password_secret_name = var.GROUPB_web_console_admin_password_secret_name
  hub_sonarw_public_key                  = module.hub_primary.sonarw_public_key
  ami                                    = var.GROUPB_ami
  ssh_key_pair = {
    ssh_private_key_file_path = local.GROUPB_gw_private_key_pem_file_path
    ssh_public_key_name       = local.GROUPB_gw_public_key_name
  }
  allowed_hub_cidrs = [data.aws_subnet.primary_hub.cidr_block, data.aws_subnet.secondary_hub.cidr_block]
  allowed_all_cidrs = local.workstation_cidr
  internal_private_key_secret_name  = var.GROUPB_internal_gw_private_key_secret_name
  internal_public_key               = try(trimspace(file(var.GROUPB_internal_gw_public_key_file_path)), null)
  instance_profile_name             = var.GROUPB_gw_instance_profile_name
  tags                              = local.tags
  providers = {
    aws = aws.GROUPB
  }
}
