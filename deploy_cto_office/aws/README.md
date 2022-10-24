# DSF AWS Deployment with Terraform - Noninteractive Setup

This project provides resources and examples to deploy the Data Security Fabric (DSF) hub, agentless gateways, and RDS services using terrraform in AWS.  The terraform resources consist of the following:
- Creating federation keys, generating passwords stored in secrets, and the required iam roles.
- Deploying a primary DSF Hub appliance
- Deploying one or multiple DSF agentless gateway appliances, automatically federated/registering to the hub
- Deploying RDS clusters and automatically on-boarding those database audit streams to DSF for audit, ingesting connection credentials for Sensitive Data Management (SDM) classicication scans.

**Note:** This tutorial initially caters to OSX users. 

## Prerequisites and Dependencies

#### **Step 1: Install required dependencies on your local system** 

1. Install [Homebrew](https://treehouse.github.io/installation-guides/mac/homebrew) on the system.
1. Install [git](https://gist.github.com/derhuerst/1b15ff4652a867391f03) using brew on the system.<br/>
    `brew install git`
1. Install [Terraform](https://www.terraform.io/) using brew on the system.<br/>
    `brew install terraform` (v0.12.20)
1. Install [awscli](https://aws.amazon.com/cli/) using brew on the system.<br/>
    `brew install awscli`
1. Install watch using brew on the system.<br/>
    `brew install watch`
1. In a terminal window, create a folder to work in, and change directories into that desired folder.  Example:<br />
    `mkdir ~/Documents/Terraform`<br />
    `cd ~/Documents/Terraform`
1. Download the latest by cloning this repo into the desired directory on the system. <br/>
    `git clone git@github.com:imperva/sonar-toolbox.git`<br />
    NOTE: If you get a permission issue in trying to clone the repo, you need to add your local public key to the profile of your user in gitlab<br/>
    `cat ~/.ssh/id_rsa.pub`<br/>
    Copy the entire contents of this output starting with "ssh-rsa", and add that into your gitlab user profile under User->Settings->SSH-KEY->Add Key.        


#### **Step 2:** 

Set up a few items in your AWS account:
1. In AWS console->IAM->Users->[your admin user], create a security credentials/cli access for a user with AdministratorAccess permissions.
    - On your local workstation, configure your local aws with the following command:<br/>
    `aws configure`<br/>
    `AWS Access Key ID [None]: YOUR_AWS_ACCESS_ID_HERE`<br/>
    `AWS Secret Access Key [None]: YOUR_AWS_SECRET_KEY_HERE`<br/>
    `Default region name [None]: us-east-2`<br/>
    `Default output format [None]: json`<br/>
1. Log into the AWS console, and create a S3 bucket: "your-sonar-configs-bucket"  
    NOTE: S3 bucket names must be globally unique
    - Select to "Block all public access" for this S3 bucket.  
    - You can create a S3 bucket from the aws cli with the following syntax: 
    `aws s3 mb s3://your-sonar-configs-bucket`
1. Download the desired version of sonar you are looking to deploy, and upload the .tar package to your s3 bucket using the following cli syntax.   
    `aws s3 cp --acl private jsonar-4.x_12345.tar.gz s3://your-sonar-configs-bucket/jsonar-4.x_12345.tar.gz`

## Getting started deploying your DSF resources with terraform

Each of the components in the deployment are broken out into folders numerically named, and will need to be deployed and destroyed in this sequence as subsequent folders have dependencies provided by the previous.<br/>
1. Provision keys, passwords, and roles:  
    - Change directories into the the 1-init folder:<br/>
    `cd ~/Documents/Terraform/sonar-toolbox/terraform/deployment/1-init`<br/>
    - Copy and rename `/deployment/1-init/variables.template` to `/deployment/1-init/variables.tf`.
    - Update the following variables in `/deployment/1-init/variables.tf`:
        - "region" - Default region to deploy DSF into
        - "environment" - Name of the environment/deployment, to be used as a prefix for the names of the various secrets, and resources that are deployed.
        - "key_pair" - Insert your naked domain name here.  
        - "s3_bucket" - This s3 bucket needs to be created manually ahead of time per instruction above.
    - Update the following variables in `/deployment/1-init/main.tf`:
        - [ admin_password, secadmin_password, sonarg_pasword, sonargd_pasword ] - Elect to use randomly generated passwords, or pre-defined passwords to be stored in aws secrets.
    - Next, run the following commands in this folder:  
        - `terraform init`
        - `terraform plan`
        - `terraform apply --auto-approve`<br/>
    - This will create federation keys, and dsf passwords to be stored in AWS secret manager, as well as the aws_iam_role used by DSF to access S3, secrets, and RDS logs.  
1. Deploy DSF Hub and Gateway(s):  
    - Change directories into the `2-dsf` folder  
    `cd ../2-dsf`
    - Copy and rename `/deployment/2-dsf/variables.template` to `/deployment/2-dsf/variables.tf`.
    - Update the following variables in `/deployment/1-init/variables.tf`:
        - "vpc_id" - ID of the VPC to deploy DSF into.
        - "subnet_id" - ID of the subnet for the Hub and Gateway.
        - "dsf_version" - Version of DSF you are looking to install.  
        - "dsf_install_tarball_path" - File name of the sonar install tar package. Example: `jsonar-4.x_12345.tar.gz`
        - "ec2_instance_type" - Instance type to use for hub and gateway instances, defaults to `r6i.2xlarge`
        - "security_group_ingress_cidrs" - List of CIDRs added to the security group to allow access to the dsf instances. Also include your current IP address in this list, this can be confirmed with the following command:  
        `curl ipinfo.io`
        - "additional_parameters" - Use this param to specify any additional parameters for the initial setup.  [See documentation](https://sonargdocs.jsonar.com/4.5/en/sonar-setup.html#noninteractive-setup) for syntax examples.  
    - Next, run the following commands in this folder:  
        - `terraform init`
        - `terraform plan`
        - `terraform apply --auto-approve`<br/>
1. Deploy RDS and onboard to DSF:  
    NOTE: Initial example is for aurora-mysql, more to come.
    - Change directories into the `3-rds-aurora-mysql` folder
    `cd ../3-rds-aurora-mysql`
    - Copy and rename `/deployment/3-rds/variables.template` to `/deployment/3-rds/variables.tf`.
    - Update the following variables in `/deployment/3-rds/variables.tf`:
        - "master_username" - Master username to access the database
        - "master_password" - Master password to access the database
        - "cluster_identifier" - Name of the database cluster
        - "rds_subnet_ids" - Array/list of subnet_ids where RDS to be deployed in.
    - Next, run the following commands in this folder:  
        - `terraform init`
        - `terraform plan`
        - `terraform apply --auto-approve`<br/>

## Accessing your environment:

- SSH Bastion Access:<br/>
    `ssh -i /path/to/your/keypair.pem ec2-user@[instance-ip-here]`  
    Example:
    `ssh -i ~/.ssh/my-keypair.pem ec2-user@1.2.3.4`

## Teardown process:

1. Run the following in each directory from 6 down to 1 sequentially:<br/>
    `terraform destroy --auto-approve`

## Troubleshooting

1. DSF troubleshooting:
    - Monitor the deployment progress by loggin into the hub and gateway instances, and monitoring the following log:<br/>
    `tail -Fn 1000 /var/log/user-data.log`
    - Verify that services were successfully started on the hub and gateway instances:<br/>
    `systemctl | grep sonar`<br/>
    - Sample output from healthy environment:<br/>
    `sonaractions.service              loaded active running   Sonaractions REST API server`<br/>
	`sonarconnections.service          loaded active running   Sonarconnection REST API server`<br/>
	`sonard.service                    loaded active running   SonarW daemon`<br/>
	`sonardispatcher.service           loaded active running   SonarG Dispatcher service`<br/>
	`sonares.service                   loaded active running   SonarElastic Server`<br/>
	`sonarfinder.service               loaded active running   SonarFinder Daemon`<br/>
	`sonargd.service                   loaded active running   Sonarg Daemon`<br/>
	`sonarkibana.service               loaded active running   SonarKibana Server`<br/>
	`sonarpysense.service              loaded active running   Python Sense`<br/>
	`sonarrsyslog.service              loaded active running   jsonar rsyslog service`<br/>
	`sonarsense.service                loaded active running   SonarSense Daemon`<br/>
	`sonarsplunk.service               loaded active running   Sonar Splunk Daemon`<br/>
	`sonarsshagent@sonarw.service      loaded active running   ssh-agent manager for user sonarw`<br/>
	`sonarusc.service                  loaded active running   SonarUSC Daemon`<br/>
	`system-sonarremote.slice          loaded active active    system-sonarremote.slice`<br/>
	`system-sonarsshagent.slice        loaded active active    system-sonarsshagent.slice`<br/>
	`sonarcleanremotelogs.timer        loaded active waiting   Run clean-remote-logs service daily`<br/>
	`sonarcollectconfigfiles.timer     loaded active waiting   Run sona-collect-config-files service daily`<br/>
	`sonareventhub.timer               loaded active waiting   run sonaeventhub`<br/>
	`sonarfinder_purge.timer           loaded active waiting   Run sonafinder purge daily`<br/>
	`sonargencrl.timer                 loaded active waiting   Run sonagencrl.service daily`<br/>
	`sonarlogrotate.timer              loaded active waiting   Daily rotation of sonar logs`<br/>
	`sonarremote@remote-default.timer  loaded active waiting   run sonaremote.service every 10 minutes`<br/>
	`sonarwebgateway.timer             loaded active waiting   run sonawebgateway`<br/>


https://aws.amazon.com/marketplace/pp?sku=634h1j7v32cuu0a7ppv7iibxv