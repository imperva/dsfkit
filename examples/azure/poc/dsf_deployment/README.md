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

## Mandatory Variables
Before initiating the Terraform deployment, it is essential to set up the following variables:
- `resource_group_location`: The region of the resource group to which all DSF components will be associated.
- `tarball_location`: Storage account and container location of the DSF installation software. az_blob is the full path to the tarball file within the storage account container. 


### Networking
- `subnet_ids`: IDs of the subnets for the deployment. If not specified, a new vpc is created.

## Default Example
To perform the default deployment, run the following command:

```bash
terraform apply -var="resource_group_location=${region}" -var='tarball_location={"az_resource_group": "${storage-resource-group}", "az_storage_account":"${storage_account_name}","az_container":"${container_name}","az_blob":"jsonar-4.13.0.10.0.tar.gz"}' -auto-approve
```
