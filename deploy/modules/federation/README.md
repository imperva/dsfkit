# DSF Federation
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module federates a DSF agentless gateway with DSF hub.

## Sonar versions
  - 4.10 (recommended)
  - 4.9

## Requirements
* Terraform v1.3.1
* SSH access - key and network path to the instance

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the DSF agentless gateway instance
* `ssh_key_pair`: AWS key pair name and path for ssh connectivity
* `web_console_admin_password`: Admin password
* `ingress_communication`: List of allowed ingress cidr patterns for the DSF agentless gw instance for ssh and internal protocols
* `ebs`: AWS EBS details
* `binaries_location`: S3 DSF installation location
* `hub_federation_public_key`: Federation public key (sonarw public ssh key). Should be taken from [hub](../hub)'s outputs

Please refer to [variables.tf](variables.tf) for additional variables with default values and additional info

## Outputs

The following [outputs](outputs.tf) are exported:

* `public_ip`: public address
* `private_ip`: private address
* `display_name`: Display name of the instance under DSF portal
* `jsonar_uid`: Id of the instance in DSF portal
* `iam_role`: AWS IAM arn
* `ssh_user`: SSH user for the instance

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}

module "globals" {
  source = "github.com/imperva/dsfkit//deploy/modules/core/globals"
}

module "dsf_gw" {
  source                        = "github.com/imperva/dsfkit//deploy/modules/agentless-gw"
  subnet_id                     = "${aws_subnet.example.id}"

  ssh_key_pair = {
    ssh_private_key_file_path   = "${var.ssh_key_path}"
    ssh_public_key_name         = "${var.ssh_name}"
  }

  ingress_communication = {
    additional_web_console_access_cidr_list = ["${var.web_console_cidr}"] # ["0.0.0.0/0"]
    full_access_cidr_list                   = ["${module.globals.my_ip}/32"] # [terraform-runner-ip-address] to allow ssh
    use_public_ip                           = true
  }

  web_console_admin_password    = random_password.pass.result
  ebs                           = {
    disk_size        = 1000
    provisioned_iops = 0
    throughput       = 125
  }
  binaries_location             = module.globals.tarball_location
  hub_federation_public_key     = module.hub.federation_public_key
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../examples/) directory.
If you want to use a specific version of the module, you can specify the version by adding the ref parameter to the source URL. For example:

```
module "dsf_gw" {
  source = "github.com/imperva/dsfkit//deploy/modules/agentless-gw?ref=1.2.0"
}
```

## SSH Access
SSH access is required to provision this module. To SSH into the DSF agentless gateway instance, you will need to provide the private key associated with the key pair specified in the key_name input variable. If direct SSH access to the DSF agentless gateway instance is not possible, you can use a bastion host as a proxy.

## Additional Information

For more information about the DSF agentless gateway and its features, please refer to the official documentation [here](https://docs.imperva.com/bundle/v4.9-sonar-user-guide/page/81265.htm). For additional information about DSF deployment using terraform, please refer to the main repo readme [here](https://github.com/imperva/dsfkit).