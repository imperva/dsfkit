# DSF Agent Gateway
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a DSF Agent Gateway on AWS as an EC2 instance.

The Gateway performs application and database monitoring, providing full visibility into how data is actually used in the enterprise, regardless of whether it is accessed directly or indirectly via applications.

## Requirements
* Terraform, refer to [versions.tf](versions.tf) for supported versions.
* An AWS account.
* Network access to Management server (MX) on port 8083 (API and WebConsole)
* Access to DAM AMIs. To request access, subscribe to [Imperva DAM AWS marketplace product](https://aws.amazon.com/marketplace/server/procurement?productId=70f80bc4-26c4-4bea-b867-c5b25b5c9f0d).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on AWS to create the DSF Agent Gateway. These resources include:
* An EC2 instance for running the software.
* An EBS volume for storage.
* AWS security groups to allow the required network access to and from the DSF instance.
* An IAM role with relevant policies.
* An AWS KMS.
* An AWS Elastic Network Interface (ENI).

The EC2 instance and EBS volume provide the computing and storage resources needed to run the DSF software. The security group controls the inbound and outbound traffic to the instance, while the IAM role grants the necessary permissions to access AWS resources. The KMS is used for encrypting sensitive data.

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the DSF instance
* `key_pair`: AWS key pair name to attach to the instance
* `mx_password`: MX password
* `secure_password`: The password used for communication between the Management Server and the Agent Gateway
* `dam_version`: Version must be in the format dd.dd.dd.dd where each dd is a number between 1-99 (e.g 14.10.1.10)
* `management_server_host_for_registration`: DSF Management server address for registration

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info.

## Outputs

Please refer to [outputs](outputs.tf) or https://registry.terraform.io/modules/imperva/dsf-agent-gw/aws/latest?tab=outputs


## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}

module "agent-gw" {
  source                                                   = "imperva/dsf-agent-gw/aws"
  subnet_id                                                = var.subnet
  key_pair                                                 = var.key_name
  mx_password                                              = var.mx_password
  secure_password                                          = var.secure_password
  dam_version                                              = var.dam_version
  management_server_host_for_registration                  = var.management_server_host_for_registration
  allowed_all_cidrs = [data.aws_vpc.selected.cidr_block]
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_agent_gw" {
  source  = "imperva/dsf-agent-gw/aws"
  version = "x.y.z"
}
```

## API Access
API access to the DSF Management server is required to provision this module. Please make sure to pass the relevant CIDR block, representing your workstation, to allow such access through the `sg_ingress_cidr` variable

## Additional Information

For more information about the DSF Agent Gateway and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/378.htm). 

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.5.5).