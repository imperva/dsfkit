# DSF CipherTrust Manager
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a CipherTrust Manager on AWS as an EC2 instance.

## CipherTrust Manager Versions
2.19 and up

## Requirements
* Terraform — refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/aws/ciphertrust-manager/versions.tf) for supported versions.
* An AWS account.
* Access to the CipherTrust AMI from AWS Marketplace (product code: `a5j8w8j2tn9crtnai795fkf6o`).

**NOTE:** For CipherTrust licensing or access questions, contact your Thales representative.

## Resources Provisioned
This Terraform module provisions several resources on AWS to create the CipherTrust Manager instance. These resources include:
* An EC2 instance running the CipherTrust Manager software.
* An EBS volume for storage.
* A network interface attached to the specified subnet and security groups.
* Optional Elastic IP and EIP association if `attach_persistent_public_ip` is enabled.
* A security group (if not provided) to allow the required network access to and from the CipherTrust Manager instance.

The EC2 instance and EBS volume provide the computing and storage resources needed to run the CipherTrust Manager software. The security group controls the inbound and outbound traffic to the instance.

## Inputs

The following input variables are **required**:

* `subnet_id`: The subnet ID to attach the CipherTrust instance to.
* `key_pair`: Name of the AWS EC2 key pair used for SSH access.
* `ebs`: AWS EBS details.

Additionally, the following variables are often **required unless defaults suffice**:

* `allowed_web_console_and_api_cidrs`: CIDRs for web console and API access (ports 443, 80).
* `allowed_ssh_cidrs`: CIDRs allowed to SSH into the instance (port 22).
* `allowed_cluster_nodes_cidrs`: CIDRs for cluster communication (port 5432).
* `allowed_ddc_agents_cidrs`: CIDRs for DDC agent access (port 11117).
* `allowed_all_cidrs`: Additional CIDRs applied to all types of access (optional).
* `ami`: Optional override for selecting a specific AMI using filters or ID.
* `instance_type`: EC2 instance type (default: `t2.xlarge`).
* `attach_persistent_public_ip`: Whether to allocate and attach an Elastic IP (default: `false`).

Refer to [inputs](https://registry.terraform.io/modules/imperva/dsf-ciphertrust-manager/aws/latest?tab=inputs) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](https://registry.terraform.io/modules/imperva/dsf-ciphertrust-manager/aws/latest?tab=outputs).

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```hcl
provider "aws" {}

module "dsf_ciphertrust_manager" {
  source = "imperva/dsf-ciphertrust-manager/aws"

  subnet_id = "subnet-xxxxxxxxxxxxxxx"
  key_pair  = "my-keypair-name"

  ebs = {
    volume_size = 256
    volume_type = "gp2"
  }

  allowed_web_console_and_api_cidrs = ["10.0.0.0/24"]
  allowed_ssh_cidrs                 = ["10.0.0.0/24"]
  allowed_cluster_nodes_cidrs       = ["10.0.1.0/24"]
  allowed_ddc_agents_cidrs          = ["10.0.2.0/24"]
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](https://github.com/imperva/dsfkit/tree/master/examples/aws) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_ciphertrust_manager" {
  source  = "imperva/dsf-ciphertrust-manager/aws"
  version = "x.y.z"

  # The rest of arguments are omitted for brevity
}
```

## CipherTrust Manager High Availability

To ensure high availability and disaster recovery, deploying multiple CipherTrust Manager instances.

To finalize the cluster nodes setup, refer to the dsf-ciphertrust-manager-cluster-setup Terraform module [here](https://registry.terraform.io/modules/imperva/ciphertrust-manager-cluster-setup/null/latest)

## Additional Information

For more information about the CipherTrust Manager and its features, refer to the official documentation [here](https://thalesdocs.com/ctp/cm/2.19/).

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.31).


