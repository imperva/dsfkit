# Multi Account example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and an Agentless Gateway (formerly Sonar) deployment.

This deployment consists of:

1. One DSF Hub
2. One Agentless Gateway
3. Federation

This example is intended for PS/customers who want to bring their own networking.
It is possible to provide as input to this example, in which subnets to deploy the DSF Hub and the DSF Agentless Gateway.
They can be in the same or in different subnets, the same or different AWS accounts, etc.<br />
Note that in case of supplying the security group id of the DSF Hub and the Agentless Gateway, because the security group of the Agentless Gateway should contain the IP of the DSF Hub (for the federation) which is not exists in this phase, the following steps should be executed: 
1. Disable the federation module
2. Run the deployment (which will fail because of the health check from the DSF Hub to the Agentless Gateway, unless you disable this flag)
3. Update the security group of the Agentless Gateway with the created DSF Hub IP
4. Enable the federation
5. Run again the deployment 

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.