# DSF Hub
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions an all-in-one data security and compliance platform, known as the DSF Hub, on AWS as an EC2 instance.

## Sonar versions
4.9 and up

## Requirements
* Terraform, refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/aws/hub/versions.tf) for supported versions.
* An AWS account.
* SSH access - key and network path to the DSF Hub instance.
* Access to the tarball containing Sonar binaries. To request access, [click here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on AWS to create the DSF Hub. These resources include:
* An EC2 instance for running the DSF Hub software.
* An EBS volume for storage.
* A security group to allow the required network access to and from the DSF Hub instance.
* An IAM role with relevant policies.
* An AWS secret containing access password, private key and access tokens.

The EC2 instance and EBS volume provide the computing and storage resources needed to run the DSF Hub software. The security group controls the inbound and outbound traffic to the instance, while the IAM role grants the necessary permissions to access AWS resources. The AWS secret is used in the process for storing password, private key, and access tokens.

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the DSF Hub instance
* `ssh_key_pair`: AWS key pair name and path for ssh connectivity
* `password`: Initial password for all users
* `ebs`: AWS EBS details
* `binaries_location`: S3 DSF installation location
* `allowed_web_console_and_api_cidrs`: List of ingress CIDR patterns allowing web console access
* `allowed_hub_cidrs`: List of ingress CIDR patterns allowing other hubs to access the DSF hub instance
* `allowed_agentless_gw_cidrs`: List of ingress CIDR patterns allowing DSF Agentless Gateways to access the DSF hub instance
* `allowed_ssh_cidrs`: List of ingress CIDR patterns allowing ssh access

In addition, the following input variables are **required** for the DR DSF Hub:
* `hadr_dr_node`: Indicate a DR DSF Hub
* `main_node_sonarw_public_key`: Public key of the sonarw user taken from the main DSF Hub output. This variable must only be defined for the DR DSF Hub
* `main_node_sonarw_private_key`: Private key of the sonarw user taken from the main DSF Hub output. This variable must only be defined for the DR DSF Hub


Refer to [inputs](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest?tab=inputs) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest?tab=outputs).

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```
provider "aws" {
}

module "dsf_hub" {
  source                        = "imperva/dsf-hub/aws"
  subnet_id                     = "subnet-*****************"

  ssh_key_pair = {
    ssh_private_key_file_path   = "ssh_keys/dsf_ssh_key-default"
    ssh_public_key_name         = "imperva-dsf-1233435325235"
  }

  allowed_web_console_and_api_cidrs = ["192.168.21.0/24"]
  allowed_hub_cidrs                 = ["10.106.108.0/24"]
  allowed_agentless_gw_cidrs        = ["10.106.104.0/24"]
  allowed_ssh_cidrs                 = ["192.168.21.0/24"]

  password                          = "dsf_hub_password"
  ebs                               = {
    disk_size        = 500
    provisioned_iops = 0
    throughput       = 125
  }
  binaries_location                 = {
    s3_bucket        = "my_S3_bucket"
    s3_region        = "us-east-1"
    s3_key           = "jsonar-4.13.0.10.0.tar.gz"
  }
  tags                              = {
    vendor        = "Imperva"
    product       = "DSF"
  }
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](https://github.com/imperva/dsfkit/tree/master/examples/aws) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_hub" {
  source  = "imperva/dsf-hub/aws"
  version = "x.y.z"

  # The rest of arguments are omitted for brevity
}
```

## DSF Hub DR Node Usage

To ensure high availability and disaster recovery, deploying an additional DSF node as a DR node is necessary. Please incorporate the following into your Terraform configuration:

```
provider "aws" {
}

module "dsf_hub_dr" {
  source                        = "imperva/dsf-hub/aws"

  # The rest of arguments are omitted for brevity
  friendly_name                 = "imperva-dsf-hub-dr"
  hadr_dr_node                  = true
  main_node_sonarw_public_key   = "dsf_hub_main_public_key"
  main_node_sonarw_private_key  = "dsf_hub_main_private_key"
}
```

To finalize the HADR registration process between the primary and DR nodes, refer to the HADR Terraform module [here](https://registry.terraform.io/modules/imperva/dsf-hadr/null/latest)

## SSH Access
SSH access is required to provision this module. To SSH into the DSF Hub instance, you will need to provide the private key associated with the key pair specified in the 
ssh_key_pair input variable. If direct SSH access to the DSF Hub instance is not possible, you can use a bastion host as a proxy:

```
module "dsf_hub" {
  source              = "imperva/dsf-hub/aws"
  # The rest of arguments are omitted for brevity
  ingress_communication_via_proxy = {
    proxy_address              = "192.168.21.4"
    proxy_private_ssh_key_path = "ssh_keys/dsf_ssh_key-default"
    proxy_ssh_user             = "ec2-user"
  }
}
```

## Additional Information

For more information about the DSF Hub and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v4.13-sonar-user-guide/page/80401.htm). 

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.3).
