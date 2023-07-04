variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "sonar_version" {
  type        = string
  default     = "4.12"
  description = "The Sonar version to install. Supported versions are: 4.11 and up. Both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch."
  validation {
    condition     = ! startswith(var.sonar_version, "4.9.") && ! startswith(var.sonar_version, "4.10.")
    error_message = "The sonar_version value must be 4.11 or higher"
  }
}

variable "aws_profile_hub" {
  type        = string
  description = "Aws profile name for the DSF Hub account"
}

variable "aws_region_hub_primary" {
  type        = string
  description = "Aws region for the primary DSF Hub (e.g us-east-2)"
}

variable "aws_region_hub_secondary" {
  type        = string
  description = "Aws region for the secondary DSF Hub (e.g us-east-2)"
}

variable "aws_profile_gw" {
  type        = string
  description = "Aws profile name for the Agentless gateway account"
}

variable "aws_region_gw_primary" {
  type        = string
  description = "Aws region for the primary Agentless gateway (e.g us-east-1)"
}

variable "aws_region_gw_secondary" {
  type        = string
  description = "Aws region for the secondary Agentless gateway (e.g us-east-1)"
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

variable "subnet_hub_primary" {
  type        = string
  description = "Aws subnet id for the primary DSF Hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_hub_secondary" {
  type        = string
  description = "Aws subnet id for the secondary DSF Hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw_primary" {
  type        = string
  description = "Aws subnet id for the primary Agentless gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw_secondary" {
  type        = string
  description = "Aws subnet id for the secondary Agentless gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "security_group_ids_hub_primary" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the primary DSF Hub (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to this example's readme for additional information on the deployment restrictions when running the deployment with this variable. If provided, no security groups are created"
}

variable "security_group_ids_hub_secondary" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the secondary DSF Hub (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to this example's readme for additional information on the deployment restrictions when running the deployment with this variable. If provided, no security groups are created"
}

variable "security_group_ids_gw_primary" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the primary Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to the readme for additional information on the deployment restrictions when running the deployment with this variable. If provided, no security groups are created"
}

variable "security_group_ids_gw_secondary" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the secondary Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to the readme for additional information on the deployment restrictions when running the deployment with this variable. If provided, no security groups are created"
}

variable "proxy_address" {
  type        = string
  description = "Proxy address used for ssh to the DSF Hub and the Agentless Gateways"
}

variable "proxy_private_address" {
  type        = string
  description = "Proxy private address used for ssh to the DSF Hub and the Agentless Gateways"
}

variable "proxy_ssh_key_path" {
  type        = string
  description = "Proxy private ssh key file path used for ssh to the DSF Hub and the Agentless Gateways"
}

variable "proxy_ssh_user" {
  type        = string
  description = "Proxy ssh user used for ssh to the DSF Hub and the Agentless Gateways"
}

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket DSF installation location"
  default     = null
}

variable "hub_instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the DSF Hub. Keep empty if you wish to create a new instance profile."
}

variable "gw_instance_profile_name" {
  type        = string
  default     = null
  description = "Instance profile to assign to the Agentless Gateway. Keep empty if you wish to create a new instance profile."
}

variable "gw_count" {
  type        = number
  default     = 1
  description = "Number of Agentless Gateways"
}

variable "password" {
  sensitive   = true
  type        = string
  default     = null
  description = "Password for all users and components including internal communication (Agentless Gateways and Hub) and also to DSF Hub web console (Randomly generated if not set)"
}

variable "password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the password value. If not set, password is used."
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null
  description = "IP ranges from which SSH/API access will be allowed to setup the deployment. If not set, the public IP of the computer where the Terraform is run is used. Format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]"
}

variable "hub_ebs_details" {
  type = object({
    disk_size        = number
    provisioned_iops = number
    throughput       = number
  })
  description = "DSF Hub compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 500
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
  description = "Agentless Gateway compute instance volume attributes. More info in sizing doc - https://docs.imperva.com/bundle/v4.10-sonar-installation-and-setup-guide/page/78729.htm"
  default = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
}

variable "hub_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF hub"
}

variable "gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the DSF gw"
}

variable "ami" {
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

variable "hub_primary_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the primary DSF Hub. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.hub_primary_key_pair == null ||
      try(var.hub_primary_key_pair.private_key_file_path != null && var.hub_primary_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'hub_primary_key_pair' variable"
  }
}

variable "hub_secondary_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the secondary DSF Hub. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.hub_secondary_key_pair == null ||
      try(var.hub_secondary_key_pair.private_key_file_path != null && var.hub_secondary_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'hub_secondary_key_pair' variable"
  }
}

variable "gw_primary_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the primary Agentless Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.gw_primary_key_pair == null ||
      try(var.gw_primary_key_pair.private_key_file_path != null && var.gw_primary_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'gw_primary_key_pair' variable"
  }
}

variable "gw_secondary_key_pair" {
  type = object({
    private_key_file_path = string
    public_key_name       = string
  })
  description = "Key pair used to SSH to the secondary Agentless Gateway. It contains the file path of the private key and the name of the public key. Keep empty if you wish to create a new key pair."
  default     = null

  validation {
    condition = (
      var.gw_secondary_key_pair == null ||
      try(var.gw_secondary_key_pair.private_key_file_path != null && var.gw_secondary_key_pair.public_key_name != null, false)
    )
    error_message = "All fields must be specified when specifying the 'gw_secondary_key_pair' variable"
  }
}

variable "hub_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the DSF Hub instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the Agentless Gateway instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF Hub and Agentless Gateway instances. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
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

variable "use_hub_as_proxy" {
  type        = bool
  default     = true
  description = "Whether to use the DSF Hub as a proxy for ssh into the Agentless Gateways"
}
