# Agentless Gateway
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a Agentless Gateway on AWS as an EC2 instance.

## Sonar versions
4.9 and up

## Requirements
* Terraform, refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/aws/agentless-gw/versions.tf) for supported versions.
* An AWS account.
* SSH access - key and network path to the DSF Hub instance.
* Access to the tarball containing Sonar binaries. To request access, [click here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform).

**NOTE:** In case you are not yet an Imperva customer, [please contact our team](https://www.imperva.com/contact-us/).

## Resources Provisioned
This Terraform module provisions several resources on AWS to create the Agentless Gateway. These resources include:
* An EC2 instance for running the Agentless Gateway software
* An EBS volume for storage
* A security group to allow the required network access to and from the Agentless Gateway instance
* An IAM role with relevant policies
* An AWS Elastic Network Interface (ENI)
* An AWS secret containing access password, private key and access tokens.

The EC2 instance and EBS volume provide the computing and storage resources needed to run the Agentless Gateway software. The security group controls the inbound and outbound traffic to the instance, while the IAM role grants the necessary permissions to access AWS resources. The AWS secret is used in the process for storing passwords, private keys, and access tokens.

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the Agentless Gateway instance
* `ssh_key_pair`: AWS key pair name and path for ssh connectivity
* `password`: Initial password for all users
* `ebs`: AWS EBS details
* `binaries_location`: S3 DSF installation location
* `hub_sonarw_public_key`: Public key of the sonarw user taken from the main DSF Hub output
* `allowed_hub_cidrs`: List of ingress CIDR patterns allowing other hubs to access the DSF hub instance
* `allowed_agentless_gw_cidrs`: List of ingress CIDR patterns allowing DSF Agentless Gateways to access the DSF hub instance
* `allowed_ssh_cidrs`: List of ingress CIDR patterns allowing ssh access

In addition, the following input variables are **required**: for the DR Agentless Gateway:
* `hadr_dr_node`: Indicate a DR DSF Hub
* `main_node_sonarw_public_key`: Public key of the sonarw user taken from the main Agentless Gateway output.
* `main_node_sonarw_private_key`: Private key of the sonarw user taken from the main Agentless Gateway output.


Refer to [inputs](https://registry.terraform.io/modules/imperva/dsf-agentless-gw/aws/latest?tab=inputs) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](https://registry.terraform.io/modules/imperva/dsf-agentless-gw/aws/latest?tab=outputs)


## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}

module "dsf_agentless_gw" {
  source                        = "imperva/dsf-agentless-gw/aws"
  subnet_id                     = "subnet-*****************"

  ssh_key_pair = {
    ssh_private_key_file_path   = "ssh_keys/dsf_ssh_key-default"
    ssh_public_key_name         = "imperva-dsf-1233435325235"
  }

  allowed_hub_cidrs                 = ["10.106.108.0/24"]
  allowed_agentless_gw_cidrs        = ["10.106.104.0/24"]
  allowed_ssh_cidrs                 = ["10.106.108.0/24"]

  password                          = "agentless_gw_password"
  ebs                               = {
    disk_size        = 150
    provisioned_iops = 0
    throughput       = 125
  }
  binaries_location                 = {
    s3_bucket        = "my_S3_bucket"
    s3_region        = "us-east-1"
    s3_key           = "jsonar-4.13.0.10.0.tar.gz"
  }
  hub_sonarw_public_key             = module.dsf_hub.sonarw_public_key
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
module "dsf_agentless_gw" {
  source  = "imperva/dsf-agentless-gw/aws"
  version = "x.y.z"
}
```

## Agentless Gateway DR Node Usage

To ensure high availability and disaster recovery, deploying an additional DSF node as a DR node is necessary. Please incorporate the following into your Terraform configuration:

```
provider "aws" {
}

module "agentless_gateway_dr" {
  source                        = "imperva/dsf-agentless-gw/aws"

  # The rest of arguments are omitted for brevity
  friendly_name                 = "imperva-dsf-agentless-gw-dr"
  hadr_dr_node                  = true
  main_node_sonarw_public_key   = "agentless_gateway_main_public_key"
  main_node_sonarw_private_key  = "agentless_gateway_main_private_key"
}
```

To finalize the HADR registration process between the primary and DR nodes, refer to the HADR Terraform module [here](https://registry.terraform.io/modules/imperva/dsf-hadr/null/latest)

## Register Agentless Gateway to DSF Hub

To enroll the Agentless Gateway with the DSF Hub, employ the [dsf-federation module](https://registry.terraform.io/modules/imperva/dsf-federation/null/latest)

```
provider "aws" {
}

module "dsf_hub" {
  source              = "imperva/dsf-hub/aws"
  # The rest of arguments are omitted for brevity
}

module "agentless_gw" {
  source              = "imperva/dsf-agentless-gw/aws"
  # The rest of arguments are omitted for brevity
}
```
Then, use the dsf_hub and agentless_gw outputs for the federation module

```
module "federation" {
  source  = "imperva/dsf-federation/null"
  count   = length(local.hub_gw_combinations)

  hub_info = {
    hub_ip_address            = module.dsf_hub.private_ip
    hub_federation_ip_address = module.dsf_hub.private_ip
    hub_private_ssh_key_path  = "ssh_keys/dsf_hub_ssh_key"
    hub_ssh_user              = module.dsf_hub.ssh_user
  }
  gw_info = {
    gw_ip_address            = module.agentless_gw.private_ip
    gw_federation_ip_address = module.agentless_gw.private_ip
    gw_private_ssh_key_path  = "ssh_keys/agentless_gateway_ssh_key"
    gw_ssh_user              = module.agentless_gw.ssh_user
  }
  depends_on = [
    module.dsf_hub,
    module.agentless_gw
  ]
}
```

**In case of an existence of DSF hub or agentless gateway DR node, the dsf-federation module should only be executed following the utilization 
of the [dsf-hadr module](https://registry.terraform.io/modules/imperva/dsf-hadr/null/latest) on every main and DR node pairs**

## SSH Access
SSH access is required to provision this module. To SSH into the DSF Hub instance, you will need to provide the private key associated with the key pair specified in the 
ssh_key_pair input variable. If direct SSH access to the DSF Hub instance is not possible, you can use a bastion host as a proxy:

```
module "dsf_agentless_gw" {
  source                       = "imperva/dsf-agentless-gw/aws"
  # The rest of arguments are omitted for brevity
  ingress_communication_via_proxy = {
    proxy_address              = "192.168.21.4"
    proxy_private_ssh_key_path = "ssh_keys/dsf_ssh_key-default"
    proxy_ssh_user             = "ec2-user"
  }
}
```

## Additional Information

For more information about the Agentless Gateway and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v4.13-sonar-user-guide/page/80401.htm). 

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.1).
