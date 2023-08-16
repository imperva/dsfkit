# DSF Hub and Agentless Gateway Upgrade example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) upgrade procedure.

This procedure consists of:

1. Preflight validations
2. Upgrade
3. Postflight validations

## Prerequisites

1. Install [git](https://git-scm.com)
2. Install [Terraform](https://developer.hashicorp.com/terraform). Latest Supported Terraform Version is 1.5.x. Using a higher version may result in unexpected behavior or errors.
3. Install [Python 3](https://www.python.org/)
4. Request access to Sonar installation software in S3 bucket [here](https://docs.google.com/forms/d/1xG_TNwAiu_WGCYoXs-YfV3Ds3nEMb60xlVBojoOXCJc)

## Running the Example
Enter the details of DSF Hubs and Agentless Gateways in the [main.tf](./main.tf) file, then run the example as follows:
```bash
terraform apply
```
To re-apply when there are no Terraform changes (the Terraform infrastructure matches the configuration), run the example as follows:
```bash
terraform apply -replace="module.sonar_upgrader.null_resource.sonar_upgrader"
```
