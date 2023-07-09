# Sonar Multi Account Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment with full HADR; deployed in multiple accounts and multiple regions.

This deployment consists of:

1. One primary DSF Hub in AWS account A, region X
2. One secondary DSF Hub in AWS account A, region Y
3. One primary Agentless Gateway in AWS account B, region X
4. One secondary Agentless Gateway in AWS account B, region Y
5. DSF Hub HADR setup
6. Agentless Gateway HADR setup
7. Federation of both primary and secondary DSF Hub with all primary and secondary Agentless Gateways

This example is intended for Professional Service and customers who want to bring their own networking, security groups, etc.</br>
It is mandatory to provide as input to this example the following variables:
1. The AWS profiles of the DSF Hub and Agentless Gateways' AWS accounts
2. The AWS regions of the DSF Hubs and Agentless Gateways
3. The subnets in which to deploy the DSF Hub and the Agentless Gateways, they can be in the same or in different subnets
4. The proxy details for SSH to the DSF Hub and the Agentless Gateways

It is not mandatory to provide the security groups Ids of the DSF Hubs and the Agentless Gateways, but in case they are provided, you should add the CIDRs and ports of the Agentless Gateways to the security groups of the DSF Hubs and vice versa before running the deployment.<br/>

## Customizing Variables

There are various ways to customize variables in Terraform, in this example, it is recommended to create a 'terrafrom.tfvars' 
file in the example's directory, and add the customized variables to it.

For example:

  ```tf
  aws_profile_hub = "profileHub"
  aws_profile_gw  = "profileGw"
  aws_region_hub_primary   = "us-east-1"
  aws_region_hub_secondary = "us-east-2"
  aws_region_gw_primary    = "us-east-1"
  aws_region_gw_secondary  = "us-west-1"
  subnet_hub_primary   = "subnet-xxxxxxxxxxxxxxxx1"
  subnet_hub_secondary = "subnet-xxxxxxxxxxxxxxxx2"
  subnet_gw_primary    = "subnet-xxxxxxxxxxxxxxxx3"
  subnet_gw_secondary  = "subnet-xxxxxxxxxxxxxxxx4"
  security_group_ids_hub_primary   = ["sg-xxxxxxxxxxxxxxxx11", "sg-xxxxxxxxxxxxxxxx12"]
  security_group_ids_hub_secondary = ["sg-xxxxxxxxxxxxxxxx21", "sg-xxxxxxxxxxxxxxxx22"]
  security_group_ids_gw_primary    = ["sg-xxxxxxxxxxxxxxxx31", "sg-xxxxxxxxxxxxxxxx32"]
  security_group_ids_gw_secondary  = ["sg-xxxxxxxxxxxxxxxx41", "sg-xxxxxxxxxxxxxxxx42"]
  proxy_address         = "x.x.x.x"
  proxy_private_address = "x.x.x.x"
  proxy_ssh_key_path    = "/proxy-ssh-key-path.pem"
  proxy_ssh_user        = "ec2-user"
  tarball_location = {
    s3_bucket = "bucket_name"
    s3_region = "us-east-1"
    s3_key    = "tarball_name"
  }
  workstation_cidr = ["10.0.0.0/24"]
  ```

Then run the deployment as usual with the following command:
  ```bash
  terraform apply
   ```
For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.

## Storing the Terraform State in an S3 Bucket

To store the Terraform state in an S3 bucket instead of locally, uncomment the '[backend.tf](./backend.tf)' file and fill in the necessary details.
Make sure that the user running the deployment has read and write access to this bucket. You can find the required permissions [here](https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-bucket-permissions).

## Deploying with DSF Hub and Agentless Gateway without Outbound Internet Access

Follow these steps to deploy a DSF Hub and/or Agentless Gateway in an environment without outbound internet access.
1. Provide a custom AMI with the following dependencies: AWS CLI, unzip, lvm2 and jq.
   You can create a custom AMI with these dependencies installed by launching an Amazon EC2 instance, installing the dependencies, and creating an AMI from the instance.
   You can then use this custom AMI when launching the DSF Hub and/or Agentless Gateway instances.
2. Update the _ami_ variable in your Terraform example with the details of the custom AMI you created.
3. Create an S3 VPC endpoint to allow the instances to access S3 without going over the internet. You can create an S3 VPC endpoint using the Amazon VPC console, AWS CLI, or an AWS SDK.
4. Create a Secrets Manager VPC endpoint to allow the instances to access the Secrets Manager without going over the internet. You can create a Secrets Manager VPC endpoint using the Amazon VPC console, AWS CLI, or an AWS SDK.
