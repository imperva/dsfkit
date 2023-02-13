# Multi Account example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and an Agentless Gateway (formerly Sonar) deployment with HADR.

This deployment consists of:

1. One DSF primary Hub
2. One DSF secondary Hub
3. One primary Agentless Gateway
4. One secondary Agentless Gateway
5. Federation
6. DSF Hub HADR
7. Agentless Gateway HADR

This example is intended for PS/customers who want to bring their own networking.
It is possible to provide as input to this example, in which subnets to deploy the DSF Hub and the Agentless Gateway.
They can be in the same or in different subnets.<br />

For a full list of this example's customization options which don't require code changes, refer to the [variables.tf](https://github.com/imperva/dsfkit/tree/1.3.6/examples/installation/basic_deployment/variables.tf) file.

Here are some examples on how to run this example with customized variables which don't require code changes.
- In order to create the Agentless gateway with an EC2 AMI version which is not the default AMI we create the instances with, run the following:
    ```bash
  terraform apply -auto-approve -var 'aws_profile="myProfile", aws_region="us-east-1", subnet_hub="subnet-xxxxxxxxxxxxxxxx1", subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2", subnet_gw="subnet-xxxxxxxxxxxxxxxx3", subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4", gw_ami_name="RHEL-7.9_HVM-20221027-x86_64-0-Hourly2-GP2"'
   ```
- In order that there will be no ssh check verification of the DSF Hub or the Agentless gateway during the deployment, run the following:
    ```bash
  terraform apply -auto-approve -var 'aws_profile="myProfile", aws_region="us-east-1", subnet_hub="subnet-xxxxxxxxxxxxxxxx1", subnet_hub_secondary="subnet-xxxxxxxxxxxxxxxx2", subnet_gw="subnet-xxxxxxxxxxxxxxxx3", subnet_gw_secondary="subnet-xxxxxxxxxxxxxxxx4", hub_skip_instance_health_verification=true, gw_skip_instance_health_verification=true'
   ```
