# Multi Account Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and an Agentless Gateway (formerly Sonar) deployment.

This deployment consists of:

1. One DSF Hub
2. One Agentless Gateway
3. Federation

This example is intended for PS/customers who want to bring their own networking.

In this example, you must provide as input the subnets in which to deploy the DSF Hub and the Agentless Gateway.
They can be in the same or in different subnets, the same or different AWS accounts, etc.<br />

It is possible to provide as input to this example the security group IDs of the DSF Hub and the Agentless Gateways. 
In this case, additional steps are required due to the fact that there is a cyclic dependency between the DSF Hub and Agentless Gateway's 
security groups.<br/> 
These steps are:
1. Disable the federation module.
2. Run the deployment (which will fail because of the health check from the DSF Hub to the Agentless Gateway, unless you disable this flag).
3. Update the security group of the Agentless Gateway with the created DSF Hub IP with the ports that are specified in [Sonar's documentation](https://docs.imperva.com/bundle/v4.11-sonar-installation-and-setup-guide/page/78702.htm).  
4. Enable the federation.
5. Run the deployment again.

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.

### Storing Terraform state in S3 bucket
To store the Terraform state in S3 bucket instead of locally, uncomment the '[backend.tf](./backend.tf)' file and fill in the necessary details.
Make sure that the user running the deployment has read and write access to this bucket. You can find the required permissions [here](https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-bucket-permissions).

### Working with DSF Hub and Agentless Gateway without outbound internet access
Follow these steps to deploy a DSF Hub and/or Agentless Gateway in an environment without outbound internet access.
1. Provide a custom AMI with the following dependencies: AWS CLI, unzip, and jq. 
   You can create a custom AMI with these dependencies installed by launching an Amazon EC2 instance, installing the dependencies, and creating an AMI from the instance. 
   You can then use this custom AMI when launching the DSF Hub and/or Agentless Gateway instances.
2. Update the _ami_ variable in your Terraform example with the details of the custom AMI you created.
3. Create an S3 VPC endpoint to allow the instances to access S3 without going over the internet. You can create an S3 VPC endpoint using the Amazon VPC console, AWS CLI, or AWS SDKs.
4. Create a Secrets Manager VPC endpoint to allow the instances to access Secrets Manager without going over the internet. You can create a Secrets Manager VPC endpoint using the Amazon VPC console, AWS CLI, or AWS SDKs.
