# DSF Hub and Agentless Gateway Upgrade example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) upgrade procedure.

This procedure consists of:

1. Preflight validations
2. Upgrade
3. Postflight validations

## Running the Example
Enter the list of DSF Hubs and Agentless Gateways in the [main.tf](./main.tf) file, then run the example as follows:
```bash
terraform apply
```
If re-applying is necessary for some reason, from the second apply onward, run the example as follows:
```bash
terraform apply -replace="module.sonar_upgrader.null_resource.sonar_upgrader"
```
