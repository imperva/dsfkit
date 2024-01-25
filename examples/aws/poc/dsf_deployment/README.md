# DSF Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This example provides a full DSF (Data Security Fabric) deployment with DSF Hub, Agentless Gateways, DAM (Database Activity Monitoring), DRA (Data Risk Analytics) and Agent and Agentless audit sources.

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
4. DRA
   - Admin server
   - Analytics servers
5. Audit sources
   - Agent audit sources (EC2 instances)
   - Agentless audit sources (RDS instances)

### Deploying Specific Modules

To deploy specific modules, you can customize the deployment by setting the corresponding variables in your Terraform configuration. Here are the instructions to deploy the following specific modules:

#### 1. DAM Only Deployment

To deploy only the DAM module, set the following variables in your Terraform configuration:
```
enable_dam = true
enable_sonar = false
enable_dra = false
```

This configuration will enable the DAM module while disabling the DSF Hub and DRA modules.

#### 2. DRA Only Deployment

To deploy only the DRA module, set the following variables in your Terraform configuration:
```
enable_dam = false
enable_sonar = false
enable_dra = true
```

This configuration will enable the DRA module while disabling the DSF Hub and DAM modules.

#### 3. Sonar Only Deployment

To deploy only the Sonar module, set the following variables in your Terraform configuration:
```
enable_dam = false
enable_sonar = true
enable_dra = false
```

This configuration will enable the Sonar module, including the DSF Hub, while disabling the DAM and DRA modules.

Feel free to customize your deployment by setting the appropriate variables based on your requirements.

## Variables
Several variables in the `variables.tf` file are important for configuring the deployment. The following variables dictate the deployment content and should be paid more attention to:

### Sub-Products
- `enable_sonar`: Enable Sonar sub-product
- `enable_dam`: Enable DAM sub-product
- `enable_dra`: Enable DRA sub-product

### Server Count
- `dra_analytics_count`: Number of DRA Analytics servers
- `agentless_gw_count`: Number of Agentless Gateways
- `agent_gw_count`: Number of Agent Gateways

### High Availability (HADR)
- `hub_hadr`: Enable DSF Hub High Availability Disaster Recovery (HADR)
- `agentless_gw_hadr`: Enable Agentless Gateway High Availability Disaster Recovery (HADR)

### Networking
- `subnet_ids`: IDs of the subnets for the deployment. If not specified, a new vpc is created.

### Audit Sources for Simulation Purposes
- `simulation_db_types_for_agentless`: Types of databases to provision and onboard to an Agentless Gateway
- `simulation_db_types_for_agent`: Types of databases to provision for Agent Gateways

## Default Example
To perform the default deployment, run the following command:

```bash
terraform apply -auto-approve
```