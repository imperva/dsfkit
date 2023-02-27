# Installation Simple Account Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub with HADR and an Agentless Gateway (formerly Sonar) deployment.

This deployment consists of:

1. One primary DSF Hub
2. One secondary DSF Hub
3. One Agentless Gateway
4. Federation
5. DSF Hub HADR setup

This example is intended for PS/customers who want to bring their own networking.
It is mandatory to provide as input to this example the subnets to deploy the DSF Hub and the Agentless Gateway.
They can be in the same or in different subnets.<br/>

#### Running terraform with variables
In the current example setting AWS profile, AWS region and the subnets of the DSF Hub and the Agentless gateway are mandatory.<br/>

This example contains variables with default values. In order to customize the variables, you can use the following:
* Run terraform with variables in a command line. For example, to run this example and specify a desired workstation CIDR that allows SSH and debugging access to the DSF Hub instead of using the default workstation CIDR where the installation is running from, run the following:
  ```bash
  terraform apply -auto-approve -var 'aws_profile="myProfile"' -var 'aws_region="us-east-1"' -var 'subnet_hub="subnet-xxxxxxxxxxxxxxxx1"' -var 'subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2"' -var 'subnet_gw="subnet-xxxxxxxxxxxxxxxx3"' -var 'workstation_cidr=["10.0.0.0/24"]'
   ```
* In case there are a lot of variables to change, it might be convenient to run terraform using a file named 'terraform.tfvars' which should contain all the mandatory and customized variables. Using 'terraform.tfvars' file replace the need to use 'var' parameter in terraform apply command. The file should be located under the same example's directory.<br/><br/> 
Example for 'terraform.tfvars' file with a desired subnets and SSH verification skip for the DSF Hub and the Agentless Gateway:<br/> 
aws_profile="myProfile"<br/>
aws_region="us-east-1"<br/>
subnet_hub="subnet-xxxxxxxxxxxxxxxx1"<br/>
subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2"<br/>
subnet_gw="subnet-xxxxxxxxxxxxxxxx3"<br/>
hub_skip_instance_health_verification=true<br/>
gw_skip_instance_health_verification=true<br/><br/>

  In this case the deployment can be run by the following command:
  ```bash
  terraform apply -auto-approve
   ```
For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](https://github.com/imperva/dsfkit/tree/1.3.6/examples/installation/simple_account_deployment/variables.tf) file.