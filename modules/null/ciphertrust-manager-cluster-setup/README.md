# DSF CipherTrust Manager Cluster Setup
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module configures a CipherTrust Manager Cluster, connecting multiple CipherTrust Manager nodes into a single secure cluster.

## Requirements
* Terraform — refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/null/ciphertrust-manager-cluster-setup/versions.tf) for supported versions.
* Two or more running CipherTrust Manager servers.
* Network access between the cluster nodes on the required ports (e.g., 5432).
* API credentials (username & password) with permissions to manage DDC settings.
* `jq` utility installed on the system executing Terraform (used in DDC node activation).

## Resources Provisioned

This module provisions the following:

* A `ciphertrust_cluster` resource defining and forming the CipherTrust cluster.
* Optional activation of the DDC Active Node using the CipherTrust REST API.

The module does **not** provision CipherTrust Manager instances — it assumes the CipherTrust Manager instances already exist and are accessible.

## Inputs

The following input variables are **required**:

* `nodes`: A list of CipherTrust Manager instances to form the cluster. Each entry must include:
    * `host` – Internal hostname or IP used for cluster joining.
    * `public_address` – Public DNS/IP used for reaching the node externally.

Additionally, the following variables are often **required unless defaults suffice**:

* `ddc_node_setup`: Configuration for registering a DDC Active Node in the cluster.
    * `enabled`: If `true`, will attempt to activate the DDC node.
    * `node_address`: The node address (typically the same as `public_address`) to register as the active node.

* `credentials`: A sensitive object containing:
    * `user`: CipherTrust API user.
    * `password`: CipherTrust API password.

Refer to [inputs](https://registry.terraform.io/modules/imperva/dsf-ciphertrust-manager-cluster-setup/null/latest?tab=inputs) for additional variables with default values and additional info.

## Outputs

This module currently defines no outputs.

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```hcl
module "ciphertrust_cluster" {
  source = "imperva/dsf-ciphertrust-manager-cluster/null"

  nodes = [
    {
      host           = "10.0.0.10"
      public_address = "3.91.122.10"
    },
    {
      host           = "10.0.0.11"
      public_address = "3.91.122.11"
    }
  ]

  ddc_node_setup = {
    enabled      = true
    node_address = "3.91.122.10"
  }

  credentials = {
    user     = "admin"
    password = "password"
  }
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](https://github.com/imperva/dsfkit/tree/master/examples/aws) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_ciphertrust_manager_cluster_setup" {
  source  = "imperva/dsf-ciphertrust-manager-cluster-setup/aws"
  version = "x.y.z"

  # The rest of arguments are omitted for brevity
}
```

## Additional Information

For more information about the DSF Hub and its features, refer to the official documentation [here](https://docs.imperva.com/bundle/v4.13-sonar-user-guide/page/80401.htm).

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.29).
