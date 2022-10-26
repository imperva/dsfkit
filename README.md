

[Temporarly, the full documentation can be found here](https://docs.google.com/document/d/1wzCrAkU2tk5e7L8pYLOeyJYai7upFBLhANWY1yDTOao/edit?usp=sharing)

<!-- # DSFKIT
DSFKIT is the official Terraform toolkit designed to automate the deployment and maintanence of Imperva's Data Security Fabric AKA DSF.

# Installation Modes
DSFKit supports two installation modes:
1. UI Mode
2. CLI Mode

## UI Mode
This mode makes use of Terraform Cloud (AKA TF Cloud), a service that allows deployng/destoring deployments via a dedicated UI.
Using this mode, only requires us to connect the Terraform Cloud to our github account where the TF code resides.
Once done, deployng the environment is done with a click of a button from Terraform Cloud infrastructures. 
Terrafrom Cloud will then pull the TF scripts from the github repository and run it remotely.

UI Mode can be used in case we need to demo DSF in our internal cloud account with a click of a button, or in case customers already own a TF Cloud Account.

### Imperva's Terraform Cloud Accounts
DSFKIT supports deployment of DSF from our internal Imperva's Terraform Account, which will be accessible for internal use (SEs, QA, Research, etc').

Imperva's Terraform Cloud account will be used deploy/destroy demo environments on AWS accounts owned by Imperva.

For each TF Cloud deployment a new 'workspace' should be created.
The name of the workspace will be always in the following format: dsf-[NAME_OF_CUSTOMER]-[NAME_OF_ENVIRONMENT].

Full deployment instruction can be found in section "Terraform Cloud Deployment"

### Customer's Terraform Cloud Account
In cases where customers have a Terraform Cloud account or they are interested to open one, they can use their Terraform Cloud account.

Full deployment instruction can be found in section "Terraform Cloud Deployment"

### Terraform Cloud Deployment
Access the Terraform Cloud Account (internal or owned by customer) and follow the following steps:

/****xx TBD xxx****/

The following arguments are required:
- AWS Secret 
- AWS Access Key
- AWS Region
- Example Name (the name of the TF recipe we want to run)


## CLI Mode
This mode makes use Terraform CLI to deploy/destroy environments.
Terraform CLI makes use of bash script, as result it can be used only in case the the user owns a linux machine and they are willing to run it locally.To run Terraform CLI follow the following steps:

### One-time Steps
1. Download git (link to official documentation)
2. Download Terraform (link to official documentation)

### Deploy
1. Clone dsfkit.git
2. cd into the requested TF "recipe": 
'cd dsfkit/deploy/example/[example_name]'
i.e. 'cd dsfkit/deploy/example/hub_hadr'
3. Apply the TF recipe: 

```bash
terraform init & sudo terraform apply -auto-approve -var="aws_region=${region}" -var="aws_access_key_id=${access_key}" -var="aws_secret_access_key=${secret_key}"
```


** NOTE that you are required to supply the following parameters: aws_access_key_id, aws_secret_access_key and region

## CLI Mode with Installer Machine
In case the the user doesn't own a linux machine or they are not willing to run it locally, DSFKIT support the deployment via DSFKIT Installer Machine, a dedicated machine that acts as a bastion server.
The user needs only to create a small ec2 machine with the following user-data:


```bash
#!/bin/bash -x 
 
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
set -e

sudo yum -y install git

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform

sudo git clone https://github.com/imperva/dsfkit.git
cd /dsfkit/deploy/examples/${example_name}

sudo terraform init
sudo terraform apply -auto-approve -var="aws_region=${region}" -var="aws_access_key_id=${access_key}" -var="aws_secret_access_key=${secret_key}"
```

This script does the following:
1. Downloads git (link to official documentation)
2. Downloads Terraform (link to official documentation)
3. Clones dsfkit.git
4. cd into the requested TF "recipe": i.e. 'cd dsfkit/deploy/example/hub_hadr'
5. Apply the TF recipe:

```bash
terraform init & sudo terraform apply -auto-approve -var="aws_region=${region}" -var="aws_access_key_id=${access_key}" -var="aws_secret_access_key=${secret_key}"
```

To automate this step DSFKIT expose a dedictaed TF script that creates the Installer Machine with the user-data. 

To use the TF Installer recipe follow the following step:

```bash
cd into dsfkit/deploy/installer_machine & terraform init & terraform apply
```

This TF script is OS-Safe as it doesn't run any bash script.

** NOTE: git and terraform are pre-requisites **

# Examples
We recognize that each customer has they own requirments:
Number of GWs, HADR deployment, networking, securoty etc'

In order to support different deployments, DSFKIT ships several builtin "recipies" - TF scripts that rapresents common deployments:
1. hub_hadr
2. hub_gw_multi_region
3. hub_gw_new_vpc

Customers with different deployment requirments can copy TF resources and modules to assemble a new TF script that fits their needs.



# IAM Roles
TBD
 -->
