# HADR
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a High Availability and Disaster Recovery support on top of an DSF Hub or Agentless Gateway deployment.

## Sonar versions
4.11 and up

## Requirements
* Terraform, refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/null/hadr/versions.tf) for supported versions.
* SSH access - key and network path to the DSF Hub or Agentless gateway instance.

## Inputs

The following input variables are **required**:

* `sonar_version`: The Sonar version to install. Supported versions are: 4.11 and up
* `dsf_main_ip`: IP of the main DSF Hub or Agentless Gateway, can be public or private
* `dsf_main_private_ip`: Private IP of the main DSF Hub or Agentless Gateway
* `dsf_dr_ip`: IP of the DR DSF Hub or Agentless Gateway, can be public or private
* `dsf_dr_private_ip`: IP of the DR DSF Hub or Agentless Gateway, can be public or private
* `ssh_key_path`: SSH key path
* `ssh_user`: SSH user

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```
module "hadr" {
  source                       = "imperva/dsf-hadr/null"
  sonar_version                = "4.13"
  dsf_main_ip                  = "192.168.21.4"
  dsf_main_private_ip          = "10.106.104.5"
  dsf_dr_ip                    = "192.168.25.4"
  dsf_dr_private_ip            = "10.106.108.5"
  ssh_key_path                 = "ssh_keys/dsf_ssh_key-default"
  ssh_user                     = "ec2-user"
  depends_on = [
    module.hub_main,
    module.hub_dr
  ]
}
```

**The utilization of the hub_hadr module is restricted to situations where the DSF Hub/Agentless Gateway's main and DR nodes are both operational and accessible**<br>
To accomplish this, initially provision the Hub main and DR nodes using the [DSF Hub module](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest) 
(similarly for the [Agentless Gateway module](https://registry.terraform.io/modules/imperva/dsf-agentless-gw/aws/latest)) outside the declaration of the HADR Terraform module:

```
provider "aws" {
}

module "dsf_hub_main" {
  source              = "imperva/dsf-hub/aws"
  # The rest of arguments are omitted for brevity
}

module "dsf_hub_dr" {
  source              = "imperva/dsf-hub/aws"
  hadr_dr_node        = true
  # The rest of arguments are omitted for brevity
}
```
Then, use the dsf_hub_main and dsf_hub_dr outputs for the HADR module

```
module "hub_hadr" {
  source                       = "imperva/dsf-hadr/null"
  sonar_version                = "4.13"
  dsf_main_ip                  = module.dsf_hub_main.private_ip
  dsf_main_private_ip          = module.dsf_hub_main.private_ip
  dsf_dr_ip                    = module.dsf_hub_dr.private_ip
  dsf_dr_private_ip            = module.dsf_hub_dr.private_ip
  ssh_key_path                 = "ssh_keys/dsf_ssh_key-default"
  ssh_user                     = module.dsf_hub_main.ssh_user
  depends_on = [
    module.dsf_hub_main,
    module.dsf_hub_dr
  ]
}
```

## SSH Access
SSH access is required to provision this module. To SSH into the DSF Hub or agentless gateway instance, you will need to provide the private key associated with the key pair specified in the 
key_name input variable. If direct SSH access to the DSF Hub instance is not possible, you can use a bastion host as a proxy:

```
module "hadr" {
  source                       = "imperva/dsf-hadr/null"
  # The rest of arguments are omitted for brevity
  ingress_communication_via_proxy = {
    proxy_address              = "192.168.21.4"
    proxy_private_ssh_key_path = "ssh_keys/dsf_ssh_key-default"
    proxy_ssh_user             = "ec2-user"
  }
}
```
