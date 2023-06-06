# Installation - Agentless Gateways Multi Account Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment with Hub HADR and Agentless Gateway HADR; deployed in multiple accounts and multiple regions.

This deployment consists of:

1. One primary DSF Hub in AWS account A, region X
2. One secondary DSF Hub in AWS account A, region Y
3. One primary Agentless Gateway in AWS account B, region X
4. One secondary Agentless Gateway in AWS account B, region Y
5. DSF Hub HADR setup
6. Agentless Gateway HADR setup
7. Federation of both primary and secondary DSF Hub with all Agentless Gateways (primary and secondary)

This example is intended for PS/customers who want to bring their own networking.
It is mandatory to provide as input to this example the subnets to deploy the DSF Hub and the Agentless Gateways.
They can be in the same or in different subnets.<br/>

In this example you should supply the proxy details for ssh to the DSF Hub and the Agentless Gateways.<br/>

Note that in case of supplying the security group id of the DSF Hubs and the Agentless Gateways, you should add the cidr of the Agentless Gateways to the security group of the DSF Hubs and vice versa before running the deployment.<br/>

#### Running terraform with variables
In the current example setting AWS profile, AWS region and the subnets of the DSF Hub and the Agentless gateways are mandatory.<br/>

This example contains variables with default values. In order to customize the variables, you can use the following:
* Run terraform with variables in a command line. For example, in order to specify the desired workstation CIDR that allows hub SSH and debugging access instead of using the default workstation CIDR where the installation is running from, run the following:<br/>
  ```bash
  terraform apply -auto-approve -var 'aws_profile_hub="profileHub"' -var 'aws_profile_gw="profileGw"' -var 'aws_region_hub_primary="us-east-1"' -var 'aws_region_hub_secondary="us-east-2"' -var 'aws_region_gw_primary="us-east-1"' -var 'aws_region_gw_secondary="us-west-1"' -var 'subnet_hub_primary="subnet-xxxxxxxxxxxxxxxx1"' -var 'subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2"' -var 'subnet_gw_primary="subnet-xxxxxxxxxxxxxxxx3"' -var 'subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4"' -var 'workstation_cidr=["10.0.0.0/24"]' -var 'proxy_address="x.x.x.x"' -var 'proxy_private_address="x.x.x.x"' -var 'proxy_ssh_key_path="/proxy-ssh-key-path.pem"' -var 'proxy_ssh_user="ec2-user"'
   ```
* In case there are a lot of variables that need to be changed, it might be more convenient to run Terraform using a file called 'terraform.tfvars' which should contain all the mandatory and customized variables. Using 'terraform.tfvars' file replace the need to use 'var' parameter in 'terraform apply' command. The file should be located in the same directory of the example.<br/><br/>
  Example for 'terraform.tfvars' file with security groups for all primary and secondary DSF Hub and Agentless Gateways:<br/>
  aws_profile_hub="profileHub"<br/>
  aws_profile_gw="profileGw"<br/>
  aws_region_hub_primary="us-east-1"<br/>
  aws_region_hub_secondary="us-east-2"<br/>
  aws_region_gw_primary="us-east-1"<br/>
  aws_region_gw_secondary="us-west-1"<br/>
  subnet_hub_primary="subnet-xxxxxxxxxxxxxxxx1"<br/>
  subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2"<br/>
  subnet_gw_primary="subnet-xxxxxxxxxxxxxxxx3"<br/>
  subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4"<br/>
  security_group_ids_hub_primary=["sg-xxxxxxxxxxxxxxxx1"]<br/>
  security_group_ids_hub_secondary=["sg-xxxxxxxxxxxxxxxx2"]<br/>
  security_group_ids_gw_primary=["sg-xxxxxxxxxxxxxxxx3"]<br/>
  security_group_ids_gw_secondary=["sg-xxxxxxxxxxxxxxxx4"]<br/>
  proxy_address="x.x.x.x"<br/>
  proxy_private_address="x.x.x.x"<br/>
  proxy_ssh_key_path="/proxy-ssh-key-path.pem"<br/>
  proxy_ssh_user="ec2-user"<br/><br/>


In this case the deployment can be run by the following command:
  ```bash
  terraform apply -auto-approve
   ```
For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](./variables.tf) file.

### Storing Terraform state in S3 bucket
To store the Terraform state in S3 bucket instead of locally, uncomment the '[backend.tf](./backend.tf)' file and fill in the necessary details.
Make sure that the user running the deployment has read and write access to this bucket. You can find the required permissions [here](https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-bucket-permissions).

### Working with DSF Hub and Agentless Gateway without outbound internet access
Follow these steps to deploy a DSF Hub and/or Agentless Gateway in an environment without outbound internet access.
1. Provide a custom AMI with the following dependencies: AWS CLI, unzip, lvm2 and jq.
   You can create a custom AMI with these dependencies installed by launching an Amazon EC2 instance, installing the dependencies, and creating an AMI from the instance.
   You can then use this custom AMI when launching the DSF Hub and/or Agentless Gateway instances.
2. Update the _ami_ variable in your Terraform example with the details of the custom AMI you created.
3. Create an S3 VPC endpoint to allow the instances to access S3 without going over the internet. You can create an S3 VPC endpoint using the Amazon VPC console, AWS CLI, or AWS SDKs.
4. Create a Secrets Manager VPC endpoint to allow the instances to access Secrets Manager without going over the internet. You can create a Secrets Manager VPC endpoint using the Amazon VPC console, AWS CLI, or AWS SDKs.
