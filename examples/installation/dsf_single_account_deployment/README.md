# DSF Single Account Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This example provides a full DSF (Data Security Fabric) deployment with DSF Hub, Agentless Gateways, DAM (Database Activity Monitoring) and DRA (Data Risk Analytics); 
deployed in a single account and two regions. 

This deployment consists of:

1. Primary and secondary DSF Hub in region 1
2. Primary and secondary Agentless Gateway Hub in region 2
3. DAM MX in region 1
4. DAM Agent Gateway in region 2
5. DRA Admin in region 1
6. DRA Analytics in region 2
7. DSF Hub HADR setup
8. Agentless Gateway HADR setup
9. Federation of both primary and secondary DSF Hub with all primary and secondary Agentless Gateways
10. Integration from MX to DSF Hub (Audit from Agent source and Security Issues)

This example is intended for Professional Services and customers who want to bring their own networking, security groups, etc.</br>
It is mandatory to provide as input to this example the following variables:
1. The AWS profile of the DSF nodes' AWS account
2. The AWS regions of the DSF nodes
3. The subnets in which to deploy the DSF nodes, they can be in the same or in different subnets

It is not mandatory to provide the security groups Ids of the DSF nodes, but in case they are provided, you should add the relevant CIDRs and ports to the security groups before running the deployment.<br/>


## Modularity
The deployment is modular and allows users to deploy one or more of the following modules:

1. Sonar
   - DSF Hub
   - DSF Hub secondary HADR (High Availability Disaster Recovery) node
   - Agentless Gateways
   - Agentless Gateways secondary HADR (High Availability Disaster Recovery) nodes
2. DAM
   - MX
   - Agent Gateways
3. DRA
   - Admin server
   - Analytic servers

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
- `dra_analytics_count`: Number of DRA Analytic servers
- `agentless_gw_count`: Number of Agentless Gateways
- `agent_gw_count`: Number of Agent Gateways

### High Availability (HADR)
- `hub_hadr`: Enable DSF Hub High Availability Disaster Recovery (HADR)
- `agentless_gw_hadr`: Enable Agentless Gateway High Availability Disaster Recovery (HADR)

### Networking
- `subnet_ids`: IDs of the subnets for the deployment

###

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.

### Customizing Variables

There are various ways to customize variables in Terraform, in this example, it is recommended to create a 'terrafrom.tfvars'
file in the example's directory, and add the customized variables to it.

For example:

  ```tf
  aws_profile = "myProfile"
  aws_region_1 = "us-east-1"
  aws_region_2 = "us-east-2"
  subnet_ids = {
    hub_primary_subnet_id            = "subnet-xxxxxxxxxxxxxxxx1"
    hub_secondary_subnet_id          = "subnet-xxxxxxxxxxxxxxxx2"
    agentless_gw_primary_subnet_id   = "subnet-xxxxxxxxxxxxxxxx3"
    agentless_gw_secondary_subnet_id = "subnet-xxxxxxxxxxxxxxxx4"
    mx_subnet_id                     = "subnet-xxxxxxxxxxxxxxxx5"
    agent_gw_subnet_id               = "subnet-xxxxxxxxxxxxxxxx6"
    dra_admin_subnet_id              = "subnet-xxxxxxxxxxxxxxxx7"
    dra_analytics_subnet_id          = "subnet-xxxxxxxxxxxxxxxx8"
  }
  security_group_ids_hub_primary            = ["sg-xxxxxxxxxxxxxxxx11", "sg-xxxxxxxxxxxxxxxx12"]
  security_group_ids_hub_secondary          = ["sg-xxxxxxxxxxxxxxxx21", "sg-xxxxxxxxxxxxxxxx22"]
  security_group_ids_agentless_gw_primary   = ["sg-xxxxxxxxxxxxxxxx31", "sg-xxxxxxxxxxxxxxxx32"]
  security_group_ids_agentless_gw_secondary = ["sg-xxxxxxxxxxxxxxxx41", "sg-xxxxxxxxxxxxxxxx42"]
  security_group_ids_mx                     = ["sg-xxxxxxxxxxxxxxxx51", "sg-xxxxxxxxxxxxxxxx52"]
  security_group_ids_agent_gw               = ["sg-xxxxxxxxxxxxxxxx61", "sg-xxxxxxxxxxxxxxxx62"]
  security_group_ids_dra_admin              = ["sg-xxxxxxxxxxxxxxxx71", "sg-xxxxxxxxxxxxxxxx72"]
  security_group_ids_dra_analytics          = ["sg-xxxxxxxxxxxxxxxx81", "sg-xxxxxxxxxxxxxxxx82"]
  tarball_location = {
    s3_bucket = "bucket_name"
    s3_region = "us-east-1"
    s3_key    = "tarball_name"
  }
  workstation_cidr = ["10.0.0.0/24"]
  license="licenses/SecureSphere_license.mprv"
  ```

Then run the deployment as usual with the following command:
  ```bash
  terraform apply
   ```
For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.

## Storing the Terraform State in an S3 Bucket

To store the Terraform state in an S3 bucket instead of locally, uncomment the '[backend.tf](./backend.tf)' file and fill in the necessary details.
Make sure that the user running the deployment has read and write access to this bucket. You can find the required permissions [here](https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-bucket-permissions).

## Deploying DSF Nodes without Outbound Internet Access

Follow these steps to deploy a DSF node (Hub, Agentless Gateway, DAR Admin or DRA Analytics) in an environment without outbound internet access.

Currently, deploying an MX and an Agent Gateway in an environment without internet access is not supported.
1. Provide a custom AMI with the following dependencies: AWS CLI, unzip, lvm2 and jq.
   You can create a custom AMI with these dependencies installed by launching an Amazon EC2 instance, installing the dependencies, and creating an AMI from the instance.
   You can then use this custom AMI when launching the DSF Hub and/or Agentless Gateway instances.
2. Update the _ami_ variable in your Terraform example with the details of the custom AMI you created.
3. Create an S3 VPC endpoint to allow the instances to access S3 without going over the internet. You can create an S3 VPC endpoint using the Amazon VPC console, AWS CLI, or an AWS SDK.
4. Create a Secrets Manager VPC endpoint to allow the instances to access the Secrets Manager without going over the internet. You can create a Secrets Manager VPC endpoint using the Amazon VPC console, AWS CLI, or an AWS SDK.
