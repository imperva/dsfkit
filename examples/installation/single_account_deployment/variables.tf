variable "deployment_name" {
  type        = string
  default     = "imperva-dsf"
  description = "Deployment name for some of the created resources. Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable."
}

variable "aws_profile" {
  type        = string
  description = "Aws profile name for the deployed resources"
}

variable "aws_region" {
  type        = string
  description = "Aws region for the deployed resources (e.g us-east-2)"
}

variable "sonar_version" {
  type        = string
  default     = "4.11"
  description = "The Sonar version to install. Sonar's supported versions are: ['4.11']"
  validation {
    condition     = var.sonar_version == "4.11"
    error_message = "This example supports Sonar version 4.11"
  }
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

variable "tarball_location" {
  type = object({
    s3_bucket = string
    s3_region = string
    s3_key    = string
  })
  description = "S3 bucket DSF installation location"
  default     = null
}

variable "subnet_hub_primary" {
  type        = string
  description = "Aws subnet id for the primary DSF Hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_hub_secondary" {
  type        = string
  description = "Aws subnet id for the secondary DSF Hub (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "subnet_gw" {
  type        = string
  description = "Aws subnet id for the primary Agentless Gateway (e.g subnet-xxxxxxxxxxxxxxxxx)"
}

variable "security_group_ids_hub" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the DSF Hub (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to this example's readme for additional information on the deployment restrictions when running the deployment with this variable."
}

variable "security_group_ids_gw" {
  type        = list(string)
  default     = []
  description = "Additional aws security group ids for the Agentless Gateway (e.g sg-xxxxxxxxxxxxxxxxx). Please refer to the readme for additional information on the deployment restrictions when running the deployment with this variable."
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
  validation {
    condition     = var.gw_count > 0
    error_message = "The gw_count value must be greater than 0."
  }
}

variable "web_console_admin_password" {
  sensitive   = true
  type        = string
  default     = null
  description = "Admin user password. If this variable is not set and 'web_console_admin_password_secret_name' is also not set, a random value is generated."
}

variable "web_console_admin_password_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the admin user password. If not set, web_console_admin_password is used."
}

variable "web_console_cidr" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "DSF Hub web console IPs range. Please specify IPs in the following format - [\"x.x.x.x/x\", \"y.y.y.y/y\"]. The default configuration opens the DSF Hub web console as a public website. It is recommended to specify a more restricted IP and CIDR range."
}

variable "workstation_cidr" {
  type        = list(string)
  default     = null # workstation ip
  description = "CIDR blocks allowing DSF Hub ssh and debugging access"
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

variable "gw_group_ebs_details" {
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
  description = "Ec2 instance type for the DSF Hub"
}

variable "gw_instance_type" {
  type        = string
  default     = "r6i.xlarge"
  description = "Ec2 instance type for the Agentless Gateway"
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

variable "hub_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the DSF Hub instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "gw_skip_instance_health_verification" {
  default     = false
  description = "This variable allows the user to skip the verification step that checks the health of the Agentless Gateway instance after it is launched. Set this variable to true to skip the verification, or false to perform the verification. By default, the verification is performed. Skipping is not recommended"
}

variable "hub_key_pem_details" {
  type = object({
    private_key_pem_file_path = string
    public_key_name           = string
  })
  description = "Key pem details used to ssh to the DSF Hub. It contains the file path of the private key and the name of the public key. Leave this variable empty if you would like us to create it."
  default     = null

  validation {
    condition = (
      var.hub_key_pem_details == null ||
      try(var.hub_key_pem_details.private_key_pem_file_path != null && var.hub_key_pem_details.public_key_name != null, false)
    )
    error_message = "All fields should be specified when specifying the hub_key_pem_details variable"
  }
}

variable "gw_key_pem_details" {
  type = object({
    private_key_pem_file_path = string
    public_key_name           = string
  })
  description = "Key pem details used to ssh to the Agentless Gateway. It contains the file path of the private key and the name of the public key. Leave this variable empty if you would like us to create it."
  default     = null

  validation {
    condition = (
      var.gw_key_pem_details == null ||
      try(var.gw_key_pem_details.private_key_pem_file_path != null && var.gw_key_pem_details.public_key_name != null, false)
    )
    error_message = "All fields should be specified when specifying the gw_key_pem_details variable"
  }
}

variable "terraform_script_path_folder" {
  type        = string
  description = "Terraform script path folder to create terraform temporary script files on the DSF Hub and Agentless Gateway instances. Use '.' to represent the instance home directory"
  default     = null
  validation {
    condition     = var.terraform_script_path_folder != ""
    error_message = "Terraform script path folder can not be an empty string"
  }
}

variable "hub_primary_role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the primary DSF Hub. Keep empty if you wish to create a new role."
}

variable "hub_secondary_role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the secondary DSF Hub. Keep empty if you wish to create a new role."
}

variable "gw_role_arn" {
  type        = string
  default     = null
  description = "IAM role to assign to the Agentless Gateway. Keep empty if you wish to create a new role."
}

variable "internal_hub_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the DSF Hub sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "internal_hub_public_key_file_path" {
  type        = string
  default     = null
  description = "The DSF Hub sonarw user public key file path - used for remote Agentless Gateway federation, HADR, etc."
}

variable "internal_gw_private_key_secret_name" {
  type        = string
  default     = null
  description = "Secret name in AWS secrets manager which holds the Agentless Gateway sonarw user private key - used for remote Agentless Gateway federation, HADR, etc."
}

variable "internal_gw_public_key_file_path" {
  type        = string
  default     = null
  description = "The Agentless Gateway sonarw user public key file path - used for remote Agentless Gateway federation, HADR, etc."
}
