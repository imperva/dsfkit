# DSF DRA Admin
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a DSF DRA Admin instance on Azure as a Virtual Machine.

## Requirements
* Terraform, refer to [versions.tf](versions.tf) for supported versions.
* An Azure account.
* DRA image or VHD located in an Azure Storage account. [Request access to vhd here](https://docs.google.com/forms/d/e/1FAIpQLSfCBUGHN04u2gK8IoxuHl4TLooBWUl7cK7ihS9Q5ZHwafNBHA/viewform). <br/>
There is an option to provide details for either the image or the VHD. When supplying the VHD details, Terraform will use them to create the image and this image will be utilized to create the Virtual Machine.  

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on Azure. These resources include:
* A Virtual Machine instance for running the DSF Admin Server software.
* Security group rules to allow the required network access to and from the DSF Admin Server instance.
* An Azure Key Vault that hold the passwords.
* An Azure network interface.

The Virtual Machine instance provide the computing resource needed to run the DSF Admin Server software. The security group rules controls the inbound and outbound traffic to the instance. The Vault is used for encrypting sensitive data (passwords).

## Inputs

The following input variables are **required**:

* `resource_group`: Resource group to provision all the resources into
* `subnet_id`: The ID of the subnet in which to launch the DSF Admin Server instance in
* `ssh_public_key`: SSH public key to access the DSF Admin Server instance
* `image_vhd_details`: Image or VHD details to create the Virtual Machine from. There is an option to provide details for either the image or the VHD. When supplying the VHD details, Terraform will use them to create the image which will be utilized to create the Virtual Machine
* `admin_ssh_password`: Password to be used to SSH to the Admin Server instance
* `admin_registration_password`: Password to be used to register Analytics Server to Admin Server

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](outputs.tf) or https://registry.terraform.io/modules/imperva/dsf-dra-admin/aws/latest?tab=outputs.

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "azurerm" {
  features {}
}

module "dra_admin" {
  source                      = "imperva/dsf-dra-admin/azurerm"
  
  resource_group              = azurerm_resource_group.example.name   
  subnet_id                   = azurerm_subnet.example.id
  ssh_public_key              = var.ssh_public_key
  
  image_vhd_details = {
    image = {
      resource_group_name = var.image_details.resource_group_name
      image_id            = var.image_details.image_id
    }
  }
  admin_ssh_password          = var.admin_ssh_password
  admin_registration_password = var.admin_registration_password
  allowed_all_cidrs           = var.allowed_all_cidrs
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/azure/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_dra_admin" {
  source  = "imperva/dsf-dra-admin/azurerm"
  version = "x.y.z"
}
```

## Additional Information

For more information about the DSF DRA Admin and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/z-kb-articles-km/page/4e487f3c.html).

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.25).