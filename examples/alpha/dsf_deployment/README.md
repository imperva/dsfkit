# DSF Deployment Example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This example provides a full DSF (Data Security Fabric) deployment with DSF Hub, Agentless Gateways, DAM (Database Activity Monitoring), DRA (Dynamic Risk Analytics), and Agent and Agentless audit sources.

## Modularity
The deployment is modular and allows users to deploy one or more of the following modules:

1. New VPC
2. Sonar
   - DSF Hub
   - DSF Hub secondary HADR (High Availability Disaster Recovery) node
   - Agentless Gateways
   - Agentless Gateways secondary HADR (High Availability Disaster Recovery) nodes
3. DAM
   - MX
   - Agent Gateways
4. DRA
   - Admin server
   - Analytic servers
5. Audit sources
   - Agent audit sources (EC2 instances)
   - Agentless audit sources (RDS instances)

## Variables
Several variables in the `variables.tf` file are important for configuring the deployment. The following variables dictate the deployment content and should be paid more attention to:

### Products
- `enable_dsf_hub`: Enable DSF Hub module
- `enable_dsf_dam`: Enable DAM module
- `enable_dsf_dra`: Enable DRA module

### Server Count
- `dra_analytics_server_count`: Number of DRA analytic servers
- `agentless_gw_count`: Number of Agentless Gateways
- `agent_gw_count`: Number of Agent Gateways

### High Availability (HADR)
- `hub_hadr`: Enable DSF Hub High Availability Disaster Recovery (HADR)
- `agentless_gw_hadr`: Enable Agentless Gateway High Availability Disaster Recovery (HADR)

### Networking
- `subnet_ids`: IDs of the subnets for the deployment. If not specified, a new vpc is created.

### Audit Sources
- `db_types_to_onboard`: Types of databases to onboard
- `agent_count`: Number of Agent audit sources

## Default Example
To perform the default deployment, run the following command:

```bash
terraform apply -auto-approve
```