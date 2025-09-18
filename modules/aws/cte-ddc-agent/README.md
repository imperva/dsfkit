# DSF CTE-DDC Agent
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions a CipherTrust Transparent Encryption (CTE) and/or Data Discovery and Classification (DDC) agent instance on AWS EC2, installs the required agent packages, registers them with a CipherTrust Manager, and handles connectivity, registration, and reboot where required. The module supports both Linux (RHEL 8.9) and Windows Server 2022.

## Requirements
* Terraform, refer to [versions.tf](https://github.com/imperva/dsfkit/blob/master/modules/aws/cte-ddc-agent/versions.tf) for supported versions.
* An AWS account.
* SSH access to the EC2 instance.
* Access from the agent instance to the CipherTrust Manager instance.
* Access to the local installer files for CTE and/or DDC agent.

## Resources Provisioned
This Terraform module provisions several resources on AWS to create the DSF CTE-DDC Agent instance. These resources include:
* An EC2 instance running Linux (RHEL 8.9) or Windows Server 2022.
* A network interface (ENI).
* A security group, unless a list of security groups is provided.
* An optional elastic public IP.
* Provisioners to install and register the CTE and/or DDC agents.

The EC2 instance provide the computing needed to run the CTE and/or DDC software. The security group controls the inbound and outbound traffic to the instance.

## Inputs

The following input variables are **required**:

* `subnet_id`: The ID of the subnet in which to launch the EC2 instance.
* `ssh_key_pair`: AWS key pair name and path for ssh connectivity.
* `cipher_trust_manager_address`: CipherTrust Manager address for agent registration.
* `os_type`: The OS to use for the agent instance. Supported values: `Red Hat`, `Windows`.
* `agent_installation`: Object indicating which agent(s) to install and the relevant installation files.

Additionally, the following variables are often **required unless defaults suffice**:

* `allowed_ssh_cidrs`: CIDRs allowed to SSH into Linux/Windows agent instance (port 22).
* `allowed_rdp_cidrs`: CIDRs allowed to RDP into Windows agent instance (port 3389).
* `attach_persistent_public_ip`: Whether to allocate and attach an Elastic IP (default: `false`).
* `use_public_ip`: Whether to use the public IP for remote SSH access (default: `false`).

Refer to [inputs](https://registry.terraform.io/modules/imperva/dsf-cte-ddc-agent/aws/latest?tab=inputs) for additional variables with default values and additional info.

## Outputs

Refer to [outputs](https://registry.terraform.io/modules/imperva/dsf-cte-ddc-agent/aws/latest?tab=outputs).

## Usage

To utilize this module with a minimal configuration, include the following in your Terraform setup:

```hcl
provider "aws" {}

module "cte_ddc_agent" {
  source = "imperva/dsf-cte-ddc-agent/aws"

  subnet_id = "subnet-xxxxxxxxxxxxxxx"

  ssh_key_pair = {
    ssh_public_key_name       = "my-keypair-name"
    ssh_private_key_file_path = "/path/to/my-private-key.pem"
  }

  cipher_trust_manager_address = "ciphertrust-manager.example.com"

  os_type = "Red Hat" # or "Windows"

  agent_installation = {
    registration_token          = "your-registration-token"
    install_cte                = true
    install_ddc                = true
    cte_agent_installation_file = "/path/to/cte-agent-installation.rpm"  # or .msi/.exe for Windows
    ddc_agent_installation_file = "/path/to/ddc-agent-installation.rpm"  # or .msi/.exe for Windows
  }

  allowed_ssh_cidrs = ["10.0.0.0/24"]
  allowed_rdp_cidrs = ["10.0.0.0/24"]  # only needed for Windows

  instance_type = "t2.large"

}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](https://github.com/imperva/dsfkit/tree/master/examples/aws) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_cte_ddc_agent" {
  source  = "imperva/dsf-cte-ddc-agent/aws"
  version = "x.y.z"

  # The rest of arguments are omitted for brevity
}
```

## Additional Information

For more information about the CipherTrust Transparent Encryption (CTE) agent and its features, refer to the official documentation [here](https://thalesdocs.com/ctp/cm/2.19/admin/cte_ag/).
For more information about the Data Discovery and Classification (DDC) agent and its features, refer to the official documentation [here](https://thalesdocs.com/ctp/cm/2.19/admin/ddc_ag/).

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.7.33).


