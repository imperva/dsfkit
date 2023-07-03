# DSF DRA Admin
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a DSF DRA Admin instance on AWS as an EC2 instance.

## Requirements
* Terraform version between v1.3.1 and v1.4.x, inclusive.
* An AWS account.
* Access to DRA software. [Request access here](https://docs.google.com/forms/d/e/1FAIpQLSc7PFqBQWdWajo83yKeaB7u9TFolXCsRAtuJdDFqwVcwAV8xA/viewform).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on AWS. These resources include:
* An EC2 instance for running the software.
* AWS security groups to allow the required network access to and from the DSF instance.
* An IAM role with relevant policies.
* AWS Secrets that hold the passwords.
* An AWS Elastic Network Interface (ENI).

The EC2 instance and EBS volume provide the computing and storage resources needed to run the DSF software. The security group controls the inbound and outbound traffic to the instance, while the IAM role grants the necessary permissions to access AWS resources. The KMS is used for encrypting sensitive data.

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the DSF instance in
* `key_pair`: AWS key pair name to attach to the instance
* `admin_password`: Password to be used to admin os user
* `admin_registration_password`: Password to be used to register Analytics Server to Admin Server

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Please refer to [outputs](outputs.tf)

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}


module "dra_admin" {
  source = "imperva/dsf-dra-admin/aws"

  subnet_id                      = local.dra_admin_subnet_id
  admin_registration_password    = local.password
  admin_password                 = local.password
  key_pair                       = local.key_pair_name
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_dra_admin" {
  source  = "imperva/dsf-dra-admin/aws"
  version = "x.y.z"
}
```

## Additional Information

For more information about the DSF DRA Admin and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/z-kb-articles-km/page/4e487f3c.html). 
For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.4.8).