# Federation
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a registration of an Agentless Gateway to an DSF Hub.

## Sonar versions
4.9 and up

## Requirements
* Terraform, refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/null/federation/versions.tf) for supported versions.
* SSH access - key and network path to the DSF Hub or Agentless gateway instance.

## Inputs

The following input variables are **required**:

* `hub_info`: DSF Hub communication information
* `gw_info`: Agentless Gateway communication information

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```
module "federation" {
  source  = "imperva/dsf-federation/null"

  hub_info = {
    hub_ip_address            = "10.106.104.5"
    hub_federation_ip_address = "10.106.104.5"
    hub_private_ssh_key_path  = "ssh_keys/dsf_hub_ssh_key"
    hub_ssh_user              = "ec2-user"
  }
  gw_info = {
    gw_ip_address            = "10.106.108.3"
    gw_federation_ip_address = "10.106.108.3"
    gw_private_ssh_key_path  = "ssh_keys/agentless_gateway_ssh_key"
    gw_ssh_user              = "ec2-user"
  }
}
```

**The utilization of the federation module is restricted to situations where the DSF Hub and Agentless Gateway nodes are both operational and accessible**<br>
To accomplish this, initially provision the [DSF Hub module](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest) 
and [Agentless Gateway module](https://registry.terraform.io/modules/imperva/dsf-agentless-gw/aws/latest) outside the declaration of the federation Terraform module:

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

## Federation and HADR
For an environment containing both main and DR machines, execute the federation module on each DSF Hub and Agentless Gateway pair. 
This includes: 
* DSF Hub main <-> Agentless Gateway main
* DSF Hub main <-> Agentless Gateway DR
* DSF Hub DR <-> Agentless Gateway main 
* DSF Hub DR <-> Agentless Gateway DR<br>

**The dsf-federation module should only be executed following the utilization of the [dsf-hadr module](https://registry.terraform.io/modules/imperva/dsf-hadr/null/latest) on every main and DR node pairs**

If your environment involves the same agentless gateway group and SSH key, you can use the following example instead of duplicating the federation modules multiple times.<br>
Please be aware that the federation module should have a dependency on the HADR module for both the DSF Hub and the Agentless Gateway:

```
module "hub_hadr" {
  source              = "imperva/dsf-hadr/null"
  # The rest of arguments are omitted for brevity
}

module "agentless_gw_hadr" {
  source              = "imperva/dsf-hadr/null"
  # The rest of arguments are omitted for brevity
}

locals {
  hub_gws_combinations = setproduct(
    [{ instance : module.hub_main, private_key_file_path : "ssh_keys/dsf_hub_main_ssh_key" }, { instance : module.hub_dr, private_key_file_path : "ssh_keys/dsf_hub_dr_ssh_key" }],
    concat(
      [for idx, val in module.agentless_gw_main : { instance : val, private_key_file_path : "ssh_keys/agentless_gateway_main_ssh_key" }],
      [for idx, val in module.agentless_gw_dr : { instance : val, private_key_file_path : "ssh_keys/agentless_gateway_dr_ssh_key" }]
    )
  )
}

module "federation" {
  count   = length(local.hub_gws_combinations)
  source  = "imperva/dsf-federation/null"
  gw_info = {
    gw_ip_address            = local.hub_gws_combinations[count.index][1].instance.private_ip
    gw_federation_ip_address = local.hub_gws_combinations[count.index][1].instance.private_ip
    gw_private_ssh_key_path  = local.hub_gws_combinations[count.index][1].private_key_file_path
    gw_ssh_user              = local.hub_gws_combinations[count.index][1].instance.ssh_user
  }
  hub_info = {
    hub_ip_address            = local.hub_gws_combinations[count.index][0].instance.private_ip
    hub_federation_ip_address = local.hub_gws_combinations[count.index][0].instance.private_ip
    hub_private_ssh_key_path  = local.hub_gws_combinations[count.index][0].private_key_file_path
    hub_ssh_user              = local.hub_gws_combinations[count.index][0].instance.ssh_user
  }
  depends_on = [
    module.hub_hadr,
    module.agentless_gw_hadr
  ]
}
```


## SSH Access
SSH access is required to provision this module. To SSH into the DSF Hub or agentless gateway instance, you will need to provide the private key associated with the key pair specified in the 
key_name input variable. If direct SSH access to the DSF Hub instance is not possible, you can use a bastion host as a proxy:

```
module "federation" {
  source  = "imperva/dsf-federation/null"
  # The rest of arguments are omitted for brevity
  hub_proxy_info = {
    proxy_address                 = "192.168.21.4"
    proxy_private_ssh_key_path    = "ssh_keys/dsf_ssh_key-default"
    proxy_ssh_user                = "ec2-user"
  }  
  gw_proxy_info = {
    proxy_address                 = "192.168.21.4"
    proxy_private_ssh_key_path    = "ssh_keys/dsf_ssh_key-default"
    proxy_ssh_user                = "ec2-user"
  }
}
```
