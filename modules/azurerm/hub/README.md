# DSF Hub
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions an all-in-one data security and compliance platform, known as the DSF Hub, on Azure as an Virtual machine.

## Sonar versions
4.9 and up

## Requirements
* Terraform, refer to [versions.tf](versions.tf) for supported versions.
* An Azure account.
* SSH access - key and network path to the DSF Hub instance.
* Access to the tarball containing Sonar binaries. To request access, click [here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on Azure to create the DSF Hub. These resources include:
* A virtual machine instance for running the DSF Hub software.
* A disk for storage.
* A security group to allow the required network access to and from the DSF Hub instance.
* An Azure network interface.
* An Azure key vault.

The virtual machine and disk provide the computing and storage resources needed to run the DSF Hub software. The security group controls the inbound and outbound traffic to the instance.

## Inputs

The following input variables are **required**:

* `resource_group`: Resource group to provision all the resources into
* `subnet_id`: The ID of the subnet in which to launch the DSF Hub instance
* `ssh_key`: ssh details
* `password`: Admin password
* `storage_details`: Azure disk details
* `binaries_location`: Tarball DSF installation location
* `sonarw_public_key`: Public key of the sonarw user taken from the main DSF Hub output. This variable must only be defined for the DR DSF Hub.
* `sonarw_private_key`: Private key of the sonarw user taken from the main DSF Hub output. This variable must only be defined for the DR DSF Hub.

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Please refer to [outputs](outputs.tf) or https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest?tab=outputs

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "azurerm" {
  features {}
}

module "globals" {
  source = "imperva/dsf-globals/azurerm"
}

module "dsf_hub" {
  source                        = "imperva/dsf-hub/azurerm"
  subnet_id                     = azurerm_subnet.example.id

  ssh_key = {
    ssh_private_key_file_path = var.ssh_key_path
    ssh_public_key            = var.ssh_public_key
  }

  allowed_all_cidrs = [data.aws_vpc.selected.cidr_block]

  password    = random_password.pass.result
  storage_details = {
    disk_size            = 1000
    disk_iops_read_write = 0
    storage_account_type = 125
  }
  binaries_location             =  module.globals.tarball_location
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_hub" {
  source  = "imperva/dsf-hub/azurerm"
  version = "x.y.z"
}
```

## SSH Access
SSH access is required to provision this module. To SSH into the DSF Hub instance, you will need to provide the private key associated with the key pair specified in the key_name input variable. If direct SSH access to the DSF Hub instance is not possible, you can use a bastion host as a proxy.

## Additional Information

For more information about the DSF Hub and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v4.12-sonar-user-guide/page/80401.htm). 

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.0).