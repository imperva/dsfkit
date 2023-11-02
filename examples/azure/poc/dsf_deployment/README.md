# DSF Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This example provides DSF (Data Security Fabric) deployment with DSF Hub, and Agentless Gateways.

## Modularity
The deployment is modular and allows users to deploy one or more of the following modules:

1. New VPC
2. Sonar
   - DSF Hub
   - DSF Hub DR HADR (High Availability Disaster Recovery) node
   - Agentless Gateways
   - Agentless Gateways DR HADR (High Availability Disaster Recovery) nodes

## Variables
Several variables in the `variables.tf` file are important for configuring the deployment. The following variables dictate the deployment content and should be paid more attention to:
- `enable_sonar`: Enable Sonar sub-product
- `agent_gw_count`: Number of Agent Gateways
- `hub_hadr`: Enable DSF Hub High Availability Disaster Recovery (HADR)
- `agentless_gw_hadr`: Enable Agentless Gateway High Availability Disaster Recovery (HADR)

### Networking
- `subnet_ids`: IDs of the subnets for the deployment. If not specified, a new vpc is created.

## Default Example
To perform the default deployment, run the following command:

```bash
terraform apply -auto-approve
```