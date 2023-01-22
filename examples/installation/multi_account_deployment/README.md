# Multi Account example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment.

This deployment consists of:

1. One Hub
2. One Gateway
3. Federation

This example is intended for PS/customers who want to bring their own networking.
It is possible to provide as input to this example, in which subnets to deploy the Hub and the Gateway.
They can be in the same or in different subnets, the same or different AWS accounts, etc.

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](https://github.com/imperva/dsfkit/tree/1.3.4/examples/installation/multi_account_deployment/variables.tf) file.