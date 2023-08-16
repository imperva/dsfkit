# DSF Hub and Agentless Gateway Upgrade POC example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) upgrade POC procedure.

This procedure consists of:

1. Preflight validations
2. Upgrade
3. Postflight validations

## Prerequisites

You may run the upgrade on your computer if using a Linux/Mac machine, or launch an EC2 and run the upgrade from there.
Prerequisites 1-4 should be satisfied in your installer machine of choice.

1. Install [git](https://git-scm.com).
2. Install [Terraform](https://developer.hashicorp.com/terraform). Latest Supported Terraform Version is 1.5.x. Using a higher version may result in unexpected behavior or errors.
3. Install [Python 3](https://www.python.org/).
4. Network access (ssh) to the deployed environment on AWS to be upgraded.
5. Request access to the Sonar installation software in S3 bucket [here](https://docs.google.com/forms/d/1xG_TNwAiu_WGCYoXs-YfV3Ds3nEMb60xlVBojoOXCJc).

## Running the Example

Enter the details of DSF Hubs and Agentless Gateways in the [main.tf](./main.tf) file, then run the example as follows:
```bash
terraform apply
```
To re-apply when there are no Terraform changes (the Terraform infrastructure matches the configuration), run the example as follows:
```bash
terraform apply -replace="module.sonar_upgrader.null_resource.sonar_upgrader"
```

## Upgrade Order

This procedure ensures a deterministic upgrade order.

As required by the Sonar product, the DSF Hub is upgraded last after the Agentless Gateways.

Among the Agentless Gateways, if more than one is specified, the upgrade order is as appears in the [main.tf](./main.tf) file in the _agentless_gws_ list.

Among the DSF Hubs, if more than one is specified, the upgrade order is as appears in the [main.tf](./main.tf) file in the _dsf_hubs_ list.

## Sonar Version Constraints

1. The minimum Sonar source version is 4.10.
2. As required by the Sonar product, the maximum upgrade version hop is 2, e.g., upgrade from 4.10 to 4.12 is supported, and upgrade from 4.10 to 4.13 is not.
3. It is possible to do a major version upgrade, e.g., from 4.10.0.0.0 to 4.12.0.10.0 or a patch upgrade, e.g., from 4.10.0.0.0 to 4.10.0.1.0.
4. _target_version_ format in the [main.tf](./main.tf) file must be 5 digits, e.g., 4.12.0.10.0 (4.12 is not supported).

## More Info
1. Fail fast - a failure in any of the upgrade procedure's steps (preflight validations, upgrade or postflight validations) stops the upgrade process to allow immediate addressing of upgrade issues.
