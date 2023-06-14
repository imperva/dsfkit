# DSF DRA Analytics
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a DSF DRA Analytics instance on AWS as an EC2 instance.

## Requirements
* Terraform version between v1.3.1 and v1.4.x, inclusive.
* An AWS account.
* Access to DRA software. (TODO how to obtain the sw)

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on AWS. These resources include:
* An EC2 instance for running the software.
* AWS security groups to allow the required network access to and from the DSF instance.
* An IAM role with relevant policies.
* AWS Secrets that hold the passwords.
* An AWS Elastic Network Interface (ENI).

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the DSF instance in
* `key_pair`: AWS key pair name to attach to the instance
* `admin_password`: Password to be used to admin os user
* `admin_registration_password`: Password to be used to register Analytics Server to Admin Server
* `archiver_password`:  Password to be used to upload archive files for analysis
* `admin_server_private_ip`: Private IP of the Admin Server (Used for registration)
* `admin_server_public_ip`: Public IP of the Admin Server (Used for verifying the analytics server is launched successfully)

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Please refer to [outputs](outputs.tf)

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}


module "dra_analytics" {
  source = "imperva/dsf-dra-analytics/aws"

  subnet_id                      = local.dra_admin_subnet_id
  admin_registration_password    = local.password
  admin_password                 = local.password
  archiver_password              = local.password
  key_pair                       = local.key_pair_name
  admin_server_public_ip         = module.dra_admin.public_ip
  admin_server_private_ip        = module.dra_admin.private_ip
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_dra_admin" {
  source  = "imperva/dsf-dra-analytics/aws"
  version = "x.y.z"
}
```

## Additional Information

For more information about the DSF DRA Analytics and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v14.11-dam-management-server-manager-user-guide/page/10068.htm). 
For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.4.8).