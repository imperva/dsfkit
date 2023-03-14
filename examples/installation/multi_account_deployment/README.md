# Multi Account Deployment example
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
