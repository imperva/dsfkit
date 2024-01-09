# DSF Agent Gateway
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a DSF Agent Gateway on Azure as a virtual machine instance.

The Gateway performs application and database monitoring, providing full visibility into how data is actually used in the enterprise, regardless of whether it is accessed directly or indirectly via applications.

## Requirements
* Terraform, refer to [versions.tf](versions.tf) for supported versions.
* An Azure account.
* Network access to Management server (MX) on port 8083 (API and WebConsole)
* Configure programmatic deployment for the desired version of Imperva DAM by [enabling it on the relevant image from the Azure Marketplace](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22imperva%22%2C%22offerId%22%3A%22imperva-dam-v14%22%2C%22planId%22%3A%22securesphere-imperva-dam-14%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D). For DAM LTS version, use [DAM LTS Azure Marketplace image](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22imperva%22%2C%22offerId%22%3A%22imperva-dam-v14-lts%22%2C%22planId%22%3A%22securesphere-imperva-dam-14%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on Azure to create the DSF Agent Gateway. These resources include:
* A virtual machine instance for running the software.
* A security group to allow the required network access to and from the DSF instance.
* An Azure network interface.

The virtual machine provide the computing resources needed to run the DSF Agent Gateway. The security group controls the inbound and outbound traffic to the instance.

## Inputs

The following input variables are **required**:

* `resource_group`: Resource group to provision all the resources into
* `subnet_id`: The ID of the subnet in which to launch the DSF instance
* `ssh_key`: ssh details
* `mx_password`: MX password
* `dam_version`: Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)
* `management_server_host_for_registration`: DSF Management server address for registration

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](outputs.tf) or https://registry.terraform.io/modules/imperva/dsf-agent-gw/azurerm/latest?tab=outputs


## Usage

To use this module, add the following to your Terraform configuration:

```
provider "azurerm" {
  features {}
}

module "agent-gw" {
  source                                                   = "imperva/dsf-agent-gw/azurerm"
  resource_group                                           = azurerm_resource_group.example.name
  subnet_id                                                = azurerm_subnet.example.id
  ssh_key = {
    ssh_private_key_file_path = var.ssh_key_path
    ssh_public_key            = var.ssh_public_key
  }
  mx_password                                              = var.mx_password
  dam_version                                              = var.dam_version
  management_server_host_for_registration                  = var.management_server_host_for_registration
  allowed_all_cidrs = [module.network.vnet_address_space]
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_agent_gw" {
  source  = "imperva/dsf-agent-gw/azurerm"
  version = "x.y.z"
}
```

## API Access
API access to the DSF Management server is required to provision this module. Please make sure to pass the relevant CIDR block, representing your workstation, to allow such access through the `allowed_web_console_and_api_cidrs` variable of the mx module.

## Additional Information

For more information about the DSF Agent Gateway and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/378.htm).

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.4).