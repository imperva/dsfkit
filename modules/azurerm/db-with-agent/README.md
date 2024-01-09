# Database on Azure virtual machine with Imperva DAM Agent Module

[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module sets up a database on an Azure virtual machine instance with an Imperva DAM (Database Activity Monitoring) agent installed, allowing agent audit source for Imperva DAM. The module provides the necessary resources to create and configure the virtual machine instance and the associated agent.

## Requirements

* Terraform v0.13 and up
* An Azure account
* Configure programmatic deployment for Ubuntu Pro 20.04 LTS image by [enabling it on the Ubuntu Pro 20.04 LTS image from the Azure Marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22canonical%22%2C%22offerId%22%3A%220001-com-ubuntu-pro-focal%22%2C%22planId%22%3A%22pro-20_04-lts%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D).
* Access to the Imperva DAM agent software. Establish an Azure Storage account along with a container, and proceed to upload the Imperva DAM agent software to this storage location as a blob.


## Resources Provisioned

This Terraform module provisions several resources on Azure to set up a virtual machine instance with an Imperva DAM agent. These resources include:

* A virtual machine instance with the Imperva DAM agent installed
* A security group to allow the required network access to and from the virtual machine instance
* An Azure network interface.

## Inputs

The following input variables are **required**:

* `resource_group`: Resource group to provision all the resources into
* `registration_params`: Agent Gateway url and password for regisration and MX site and service group to assign the agent to.
* `subnet_id`: Subnet id for the virtual machine instance
* `ssh_key`: ssh details
* `binaries_location`: Imperva DAM agent installation location

Refer to the [variables.tf](variables.tf) file for additional variables with default values and additional information.

## Usage

To use this module, add the following to your Terraform configuration:

```hcl
provider "azurerm" {
  features {}
}

module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/azurerm"
  resource_group    = azurerm_resource_group.example.name
  subnet_id         = var.agent_gw_subnet_id
  ssh_key = {
    ssh_private_key_file_path = var.ssh_key_path
    ssh_public_key            = var.ssh_public_key
  }
  registration_params = {
    agent_gateway_host = module.agent_gw.private_ip
    secure_password    = var.password
    server_group       = module.mx.configuration.default_server_group
    site               = module.mx.configuration.default_site
  }
  binaries_location    = {
    az_resource_group  = azurerm_resource_group.example.name
    az_storage_account = "storage_account_name"
    az_container       = "container_name"
    az_blob            = "Imperva-ragent-UBN-px86_64-b14.6.0.60.0.636085.bsx"
  }
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/azurerm"
  version = "x.y.z"
}
```

## Additional Information

For more information about the DAM Agent and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/378.htm).
For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.4).
