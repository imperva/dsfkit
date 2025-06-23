# Database on EC2 Instance with Imperva DAM Agent Module

[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module sets up a database on an EC2 instance with an Imperva DAM (Database Activity Monitoring) agent installed, allowing agent audit source for Imperva DAM. The module provides the necessary resources to create and configure the EC2 instance and the associated agent.

## Requirements

* Terraform v0.13 and up
* An AWS account
* Access to the Imperva DAM agent software. To request access, [click here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform).


## Resources Provisioned

This Terraform module provisions several resources on AWS to set up an EC2 instance with an Imperva DAM agent. These resources include:

* An EC2 instance with the Imperva DAM agent installed
* A security group to allow the required network access to and from the EC2 instance
* An IAM role with relevant policies attached to the EC2 instance

## Inputs

The following input variables are **required**:

* `registration_params`: Agent Gateway url and password for regisration and MX site and service group to assign the agent to.
* `subnet_id`: Subnet id for the ec2 instance
* `key_pair`: Key pair for the ec2 instance

Refer to the [variables.tf](variables.tf) file for additional variables with default values and additional information.

## Usage

To use this module, add the following to your Terraform configuration:

```hcl
provider "aws" {
}

module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/aws"

  subnet_id         = var.agent_gw_subnet_id
  key_pair          = var.key_pair

  registration_params = {
    agent_gateway_host = module.agent_gw.private_ip
    secure_password    = var.password
    server_group       = module.mx.configuration.default_server_group
    site               = module.mx.configuration.default_site
  }
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "db_with_agent" {
  source  = "imperva/dsf-db-with-agent/aws"
  version = "x.y.z"
}
```

## Additional Information

For more information about the DSF Agent Gateway and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v14.11-database-activity-monitoring-user-guide/page/378.htm). 
For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.30).