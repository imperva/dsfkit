# DSF Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This example provides DSF (Data Security Fabric) deployment with DSF Hub, Agentless Gateways, DAM (Database Activity Monitoring) and Agent audit sources.

## Modularity
The deployment is modular and allows users to deploy one or more of the following modules:

1. New VPC
2. Sonar
   - DSF Hub
   - DSF Hub DR HADR (High Availability Disaster Recovery) node
   - Agentless Gateways
   - Agentless Gateways DR HADR (High Availability Disaster Recovery) nodes
3. DAM
   - MX
   - Agent Gateways
4. Audit sources
   - Agent audit sources (virtual machine instances)

### Deploying Specific Modules

To deploy specific modules, you can customize the deployment by setting the corresponding variables in your Terraform configuration. Here are the instructions to deploy the following specific modules:

#### 1. DAM Only Deployment

To deploy only the DAM module, set the following variables in your Terraform configuration:
```
enable_dam = true
enable_sonar = false
```

This configuration will enable the DAM module while disabling the Sonar module.

#### 2. Sonar Only Deployment

To deploy only the Sonar module, set the following variables in your Terraform configuration:
```
enable_dam = false
enable_sonar = true
```

This configuration will enable the Sonar module, including the DSF Hub, while disabling the DAM module.

Feel free to customize your deployment by setting the appropriate variables based on your requirements.

## Variables
Several variables in the `variables.tf` file are important for configuring the deployment. The following variables dictate the deployment content and should be paid more attention to:

### Sub-Products
- `enable_sonar`: Enable Sonar sub-product
- `enable_dam`: Enable DAM sub-product

### Server Count
- `agentless_gw_count`: Number of Agentless Gateways
- `agent_gw_count`: Number of Agent Gateways

### High Availability (HADR)
- `hub_hadr`: Enable DSF Hub High Availability Disaster Recovery (HADR)
- `agentless_gw_hadr`: Enable Agentless Gateway High Availability Disaster Recovery (HADR)

### Audit Sources for Simulation Purposes
- `simulation_db_types_for_agent`: Types of databases to provision for Agent Gateways

## Mandatory Variables
Before initiating the Terraform deployment, it is essential to set up the following variables:
- `resource_group_location`: The region of the resource group to which all DSF components will be associated.
- `tarball_location`: Storage account and container location of the DSF installation software. az_blob is the full path to the tarball file within the storage account container. 
- `dam_agent_installation_location`: Storage account and container location of the DAM Agent installation software. az_blob is the full path to the installation file within the storage account container.
- `dam_license`: DAM license file path.

## Default Example
To perform the default deployment, run the following command:

```bash
terraform apply -var="resource_group_location=${region}" -var='tarball_location={"az_resource_group": "${storage-resource-group}", "az_storage_account":"${storage_account_name}","az_container":"${container_name}","az_blob":"jsonar-4.13.0.10.0.tar.gz"}' -var='dam_agent_installation_location={"az_resource_group": "${storage-resource-group}", "az_storage_account":"${storage_account_name}","az_container":"${container_name}","az_blob":"Imperva-ragent-UBN-px86_64-b14.6.0.60.0.636085.bsx"}' -var="dam_license=/path/to/license/file" -auto-approve
```
