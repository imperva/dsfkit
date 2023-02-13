# Installation Basic Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and an Agentless Gateway (formerly Sonar) deployment with HADR.

This deployment consists of:

1. One DSF primary Hub
2. One DSF secondary Hub
3. One primary Agentless Gateway
4. One secondary Agentless Gateway
5. Federation
6. DSF Hub HADR setup
7. Agentless Gateway HADR setup

This example is intended for PS/customers who want to bring their own networking.
It is mandatory to provide as input to this example the subnets to deploy the DSF Hub and the Agentless Gateway.
They can be in the same or in different subnets.<br/>

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](https://github.com/imperva/dsfkit/tree/1.3.6/examples/installation/basic_deployment/variables.tf) file.

Here are some examples on how to run this example with customized variables which don't require code changes:
- In order to create the Agentless gateway with an EC2 AMI version which is not the default AMI we create the instances with, use the following variable:
  gw_ami_name="RHEL-7.9_HVM-20221027-x86_64-0-Hourly2-GP2"
- In order that there will be no SSH check verification of the DSF Hub and the Agentless gateway during the deployment, use the following variables:
  hub_skip_instance_health_verification=true, gw_skip_instance_health_verification=true

In the current example the subnets of the DSH Hub and the Agentless gateway are mandatory.

#### Running terraform with variables
* There is an option to run terraform with variables in a command line. For example, in order to run terraform with a specific EC2 AMI version for the Agentless gateway, run the following:
  ```bash
  terraform apply -auto-approve -var 'aws_profile="myProfile", aws_region="us-east-1", subnet_hub="subnet-xxxxxxxxxxxxxxxx1", subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2", subnet_gw="subnet-xxxxxxxxxxxxxxxx3", subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4", gw_ami_name="RHEL-7.9_HVM-20221027-x86_64-0-Hourly2-GP2"'
   ```
* In case there are a lot of variables to change, it might be convenient to run terraform using a file named 'terraform.tfvars' which should contain all the mandatory and customized variables. Using 'terraform.tfvars' file replace the need to use 'var' parameter in terraform apply command.<br/><br/> 
Example for 'terraform.tfvars' file:<br/> 
aws_profile="myProfile"<br/>
aws_region="us-east-1"<br/>
subnet_hub="subnet-xxxxxxxxxxxxxxxx1"<br/>
subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2"<br/>
subnet_gw="subnet-xxxxxxxxxxxxxxxx3"<br/>
subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4"<br/>
hub_skip_instance_health_verification=true<br/>
gw_skip_instance_health_verification=true<br/><br/>

  In this case the deployment can be run by the following command:
  ```bash
  terraform apply -auto-approve
   ```
