variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "aws_profile" {
  type        = string
  description = "AWS profile name for the deployed resources"
}

variable "aws_region_1" {
  type        = string
  description = "The first AWS region for the deployed resources (e.g us-east-2)"
}

variable "aws_region_2" {
  type        = string
  description = "The second AWS region for the deployed resources (e.g us-east-2)"
}

variable "additional_tags" {
  type        = list(string)
  default     = []
  description = "Additional tags to add to the DSFKit resources. Please put tags in the following format - Key: Name. For example - [\"Key1=Name1\", \"Key2=Name2\"]"
  validation {
    condition = alltrue([
      for tag_pair in var.additional_tags : can(regex("^([a-zA-Z0-9+\\-_.:/@]+)=([a-zA-Z0-9+\\-_.:/]+)$", tag_pair))
    ])
    error_message = "Invalid tag format. All values must be in the format of 'key=value', where 'key' is a valid AWS tag name and 'value' is a valid AWS tag value. Note that the '=' character is not allowed in either the key or the value."
  }
}

variable "enable_sonar" {
  type        = bool
  default     = true
  description = "Provision DSF Hub and Agentless Gateways (formerly Sonar). To provision only a DSF Hub, set agentless_gw_count to 0."
}

variable "enable_dam" {
  type        = bool
  default     = true
  description = "Provision DAM MX and Agent Gateways"
}

variable "enable_dra" {
  type        = bool
  default     = true
  description = "Provision DRA Admin and Analytics"
}

variable "agentless_gw_count" {
  type        = number
  default     = 1
  description = "Number of Agentless Gateways. Provisioning Agentless Gateways requires the enable_sonar variable to be set to 'true'."
}

variable "agent_gw_count" {
  type        = number
  default     = 2 # Minimum count for a cluster
  description = "Number of Agent Gateways. Provisioning Agent Gateways requires the enable_dam variable to be set to 'true'."
}

variable "dra_analytics_count" {
  type        = number
  default     = 1
  description = "Number of DRA Analytics servers. Provisioning Analytics servers requires the enable_dra variable to be set to 'true'."
}

variable "password" {
  sensitive   = true
  type        = string
  default     = null
  description = "Password for all users and components including internal communication (DRA instances, Agent and Agentless Gateways, MX and Hub), MX and DSF Hub web console. If this and the 'password_secret_name' variables are not set, a random value is generated."
}

variable "password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the password value. If not set, password is used."
}

variable "proxy_address" {
  type        = string
  description = "Proxy address used for ssh to the DSF Hub and the Agentless Gateways"
  default     = null
}

variable "proxy_private_address" {
  type        = string
  description = "Proxy private address used for ssh to the DSF Hub and the Agentless Gateways"
  default     = null
}

variable "proxy_ssh_key_path" {
  type        = string
  description = "Proxy private ssh key file path used for ssh to the DSF Hub and the Agentless Gateways"
  default     = null
}

variable "proxy_ssh_user" {
  type        = string
  description = "Proxy ssh user used for ssh to the DSF Hub and the Agentless Gateways"
  default     = null
}

##############################
#### Networking variables ####
##############################
variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub and MX web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the public IP of the computer where the Terraform is run is used. Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "subnet_ids" {
  type = object({
    hub_main_subnet_id               = string
    hub_dr_subnet_id                 = string
    agentless_gw_main_subnet_id      = string
    agentless_gw_dr_subnet_id        = string
    mx_subnet_id                     = string
    agent_gw_subnet_id               = string
    dra_admin_subnet_id              = string
    dra_analytics_subnet_id          = string
  })
  description = "The IDs of existing subnets to deploy resources in"
  validation {
    condition     = var.subnet_ids == null || try(var.subnet_ids.hub_main_subnet_id != null && var.subnet_ids.hub_dr_subnet_id != null && var.subnet_ids.agentless_gw_main_subnet_id != null && var.subnet_ids.agentless_gw_dr_subnet_id != null && var.subnet_ids.mx_subnet_id != null && var.subnet_ids.agent_gw_subnet_id != null && var.subnet_ids.dra_admin_subnet_id != null && var.subnet_ids.dra_analytics_subnet_id != null, false)
    error_message = "Value must either be null or specified for all"
  }
  validation {
    condition     = var.subnet_ids == null || try(alltrue([for subnet_id in values({ for k, v in var.subnet_ids : k => v if k != "db_subnet_ids" }) : length(subnet_id) >= 15 && substr(subnet_id, 0, 7) == "subnet-"]), false)
    error_message = "Subnet id is invalid. Must be subnet-********"
  }
}

###################################
#### Security groups variables ####
###################################

variable "security_group_ids_hub_main" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the main DSF Hub (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_hub_dr" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the DR DSF Hub (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_gw_main" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the main Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_gw_dr" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the DR Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_mx" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the DAM MX (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_agent_gw" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the Agent Gateway (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_dra_admin" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the DRA Admin (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "security_group_ids_dra_analytics" {
  type        = list(string)
  default     = []
  description = "AWS security group Ids for the DRA Analytics (e.g sg-xxxxxxxxxxxxxxxxx). If provided, no security groups are created and all allowed_*_cidrs variables are ignored."
}

variable "dra_admin_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the Agent Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.dra_admin_key_pair == null ||
      try(var.dra_admin_key_pair.private_key_file_path != null && var.dra_admin_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'dra_admin_key_pair' variable"
  }
}

variable "dra_analytics_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the Agent Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.dra_analytics_key_pair == null ||
      try(var.dra_analytics_key_pair.private_key_file_path != null && var.dra_analytics_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'dra_analytics_key_pair' variable"
  }
}

##############################
####    Sonar variables   ####
##############################

variable "sonar_version" {
  type        = string
  default     = "4.12"
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  validation {
    condition     = !startswith(var.sonar_version, "4.9.") && !startswith(var.sonar_version, "4.10.")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket location of the DSF installation software. s3_key is the full path to the tarball file within the bucket, for example, 'prefix/jsonar-x.y.z.w.u.tar.gz'"
  default     = null
}

variable "hub_instance_type" {
  type        = string
  default     = "r6i.2xlarge"
  description = "Ec2 instance type for the DSF Hub"
}

variable "agentless_gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the Agentless Gateway"
}

variable "sonar_ami" {
  type = object({
    id               = string
    name             = string
    username         = string
    owner_account_id = string
  })
  description = <<EOF
This variable is used for selecting an AWS machine image for the DSF Hub and Agentless Gateway based on various filters. It is an object type variable that includes the following fields: id, name, username, and owner_account_id.
If set to null, the recommended image will be used.
The "id" and "name" fields are used to filter the machine image by ID or name, respectively. To select all available images for a given filter, set the relevant field to "*". The "username" field is mandatory and used to specify the AMI username.
The "owner_account_id" field is used to filter images based on the account ID of the owner. If this field is set to null, the current account ID will be used. The latest image that matches the specified filter will be chosen.
EOF
  default     = null
}

variable "hub_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the DSF Hub EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}

variable "agentless_gw_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the Agentless Gateway EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}

variable "hub_hadr" {
  type        = bool
  default     = true
  description = "Provisions a High Availability and Disaster Recovery node for the DSF Hub"
}

variable "agentless_gw_hadr" {
  type        = bool
  default     = true
  description = "Provisions a High Availability and Disaster Recovery node for the Agentless Gateway"
}

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 250
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "agentless_gw_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "hub_main_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the main DSF Hub. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.hub_main_key_pair == null ||
      try(var.hub_main_key_pair.private_key_file_path != null && var.hub_main_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'hub_main_key_pair' variable"
  }
}

variable "hub_dr_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the DR DSF Hub. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.hub_dr_key_pair == null ||
      try(var.hub_dr_key_pair.private_key_file_path != null && var.hub_dr_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'hub_dr_key_pair' variable"
  }
}

variable "agentless_gw_main_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the main Agentless Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.agentless_gw_main_key_pair == null ||
      try(var.agentless_gw_main_key_pair.private_key_file_path != null && var.agentless_gw_main_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'agentless_gw_main_key_pair' variable"
  }
}

variable "agentless_gw_dr_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the DR Agentless Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.agentless_gw_dr_key_pair == null ||
      try(var.agentless_gw_dr_key_pair.private_key_file_path != null && var.agentless_gw_dr_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'agentless_gw_dr_key_pair' variable"
  }
}

variable "additional_install_parameters" {
  default     = ""
  description = "Additional params for installation tarball. More info in https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/80035.htm"
}

variable "hub_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the DSF Hub instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended."
}

variable "agentless_gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the Agentless Gateway instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended."
}

variable "sonar_terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF Hub and Agentless Gateway instances. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.sonar_terraform_script_path_folder != ""
    error_message = "Terraform script path folder cannot be an empty string"
  }
}

variable "sonarw_hub_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the DSF Hub sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_hub_public_key_file_path" {
  type        = string
  default     = null
  description = "The DSF Hub sonarw user public key file path - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_gw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the Agentless Gateway sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "sonarw_gw_public_key_file_path" {
  type        = string
  default     = null
  description = "The Agentless Gateway sonarw user public key file path - used for remote Agentless Gateway federation, HADR, etc."
}

##############################
####    DAM variables     ####
##############################

variable "dam_version" {
  type        = string
  description = "The DAM version to install"
  default     = "14.12.1.10"
  validation {
    condition     = can(regex("^(\\d{1,2}\\.){3}\\d{1,2}$", var.dam_version))
    error_message = "Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)"
  }
}

variable "dam_license" {
  description = <<EOF
  DAM license information. Must be one of the following:
  1. Activation code (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  2. License file path
  EOF
  type        = string
}

variable "large_scale_mode" {
  type = object({
    mx       = bool
    agent_gw = bool
  })
  description = "DAM large scale mode"
  validation {
    condition     = var.large_scale_mode.mx == false || var.large_scale_mode.agent_gw == true
    error_message = "MX large scale mode requires setting large scale mode in the Agentless Gateway as well"
  }
  default = {
    mx       = true
    agent_gw = true
  }
}

variable "mx_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "MX compute instance volume attributes"
  default = {
    volume_size = 160
    volume_type = "gp2"
  }
}

variable "agent_gw_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "Agent Gateway compute instance volume attributes"
  default = {
    volume_size = 160
    volume_type = "gp2"
  }
}

variable "mx_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the MX. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.mx_key_pair == null ||
      try(var.mx_key_pair.private_key_file_path != null && var.mx_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'mx_key_pair' variable"
  }

}

variable "agent_gw_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the Agent Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.agent_gw_key_pair == null ||
      try(var.agent_gw_key_pair.private_key_file_path != null && var.agent_gw_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'agent_gw_key_pair' variable"
  }

}

variable "mx_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the MX EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}

variable "agent_gw_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the Agent Gateway EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}

variable "cluster_name" {
  type        = string
  description = "The name of the Agent Gateway Cluster to provision when agent_gw_count >= 2. Keep empty to use an auto-generated name."
  default     = null
}

##############################
####    DRA variables   ####
##############################

variable "dra_version" {
  type        = string
  default     = "4.12.0.10"
  description = "The DRA version to install. Supported versions are 4.11.0.10 and up. Both long and short version formats are supported, for example, 4.11.0.10 or 4.11. The short format maps to the latest patch."
  validation {
    condition     = !startswith(var.dra_version, "4.10.") && !startswith(var.dra_version, "4.9.") && !startswith(var.dra_version, "4.8.") && !startswith(var.dra_version, "4.3.") && !startswith(var.dra_version, "4.2.") && !startswith(var.dra_version, "4.1.")
    error_message = "The dra_version value must be 4.11.0.10 or higher"
  }
}

variable "dra_admin_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "DRA Admin compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 260
    volume_type = "gp3"
  }
}

variable "dra_analytics_ebs_details" {
  type = object({
    volume_size = number
    volume_type = string
  })
  description = "DRA Analytics compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.11-data-risk-analytics-installation-guide/page/69846.htm"
  default = {
    volume_size = 1010
    volume_type = "gp3"
  }
}

variable "dra_admin_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the DRA Admin EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}

variable "dra_analytics_instance_profile_name" {
  type        = string
  description = "Instance profile to assign to the DRA Analytics EC2. Keep empty if you wish to create a new instance profile."
  default     = null
}
