# DSF MsSQL
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions MsSQL instance and configure audit on it.
It should be used for poc / pov / lab purposes.

## Requirements
* Terraform v0.13 and up
* An Azure account
* Permissions to create MsSQL, Eventhub and Storage account (for configuring the audit). Required permissions can be found [here](/permissions_samples/azure/OnboardMssqlRdsWithDataPermissions.txt).

## Resources Provisioned
This Terraform module provisions several resources on AWS to create and onboard the MsSQL with synthetic data on it. These resources include:
* A MsSQL instance
* A security group to allow the required network access to and from the MsSQL instance

## Inputs

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Refer to [outputs.tf](outputs.tf) for additional variables with default values and additional info.

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "azurerm" {
  features {
  }
}

module "mssql" {
  source            = "imperva/dsf-poc-db-onboarder/azurerm//modules/mssql-db"
  resource_group    = var.resource_group
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_mssql" {
  source  = "imperva/dsf-poc-db-onboarder/azurerm//modules/mssql-db"
  version = "x.y.z"
}
```

## Additional Information

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.22).