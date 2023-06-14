# Data Security Fabric (DSF) Kit Deployment Guide
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

# DSFKit

Imperva DSFKit is the official Terraform toolkit designed to automate the deployment of Imperva's Data Security Fabric.
The DSF can be easily deployed by following the steps in this guide which are currently available for deployments on AWS only.

DSFKit enables you to deploy the full suite of the DSF sub-products - DSF Hub & Agentless Gateway (formerly Sonar), 
DAM (Data Activity Monitoring) and DRA (Data Risk Analytics). 

Currently, DSFKit supports deployments on AWS cloud. In the near future, it will support other major public clouds, 
on-premises (vSphere) and hybrid environments.

# About This Guide

#### Audience

This guide is intended for Imperva Sales Engineers (SE) for the purpose of Proof-of-Concept (POC) demonstrations and preparing for these demonstrations, aka, Lab.

It is also intended for Imperva Professional Services (PS) and customers for actual deployments of DSF.

#### Purpose and Scope

This guide covers the following main topics. Additional guides are referenced throughout, as listed in the Quick Links section below.

* How to deploy Imperva’s Data Security Fabric (DSF) with step-by-step instructions.
* How to verify that the deployment was successful using the DSFKit output.
* How to undeploy DSF with step-by-step instructions.

#### Typographical Conventions

This guide uses several text styles for an enhanced readability and several call-out features. Learn about their meaning from the table below.

<table>
  <tr>
   <td><strong>Convention</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>Code, commands or user input
   </td>
   <td>
   
   ```
   This font will be used to denote code blocks, commands or user input. 
   ```

   </td>
  </tr>
  <tr>
   <td>Instruction to change code, commands or user input
   </td>
   <td>

   ```
   >>>> This font along with the >>>> prefix will be used to instruct the user 
        to change the code, command or the user input rather than copy the exact
        text as it appears in this guide. 
   ```

   </td>
  </tr>
  <tr>
   <td>Placeholder
   </td>
   <td>

   ```bash
   ${placeholder}: Used within commands to indicate that the user should replace the placehodler with a value, including the $, { and }. 
   ```

   </td>
  </tr>
  <tr>
   <td>Hyperlinks
   </td>
   <td>Clickable URLs embedded within the guide are blue and underlined. E.g., <a href="http://www.imperva.com">www.imperva.com</a>
   </td>
  </tr>
</table>

#### Quick Links

This guide references the following information and links, some of which are available via the Documention Portal on the Imperva website: [https://docs.imperva.com](https://docs.imperva.com).  (Login required)

<table>
  <tr>
   <td><strong>Link</strong>
   </td>
   <td><strong>Details</strong>
   </td>
  </tr>
   <tr>
      <td><a href="https://docs.imperva.com/bundle/v1-data-security-overview-and-integration-guide/page/78571.htm">Data Security Fabric v1.0</a>
      </td>
      <td>DSF Overview
      </td>
   </tr>
  <tr>
   <td>
   <a href="https://docs.imperva.com/howto/ed55ac24">Sonar v4.11</a>

   <a href="https://docs.imperva.com/howto/66707580">DAM v14.11</a>

   <a href="https://docs.imperva.com/howto/4e487f3c">DRA v4.11</a>
   </td>
   <td>DSF Components Overview
   </td>
  </tr>
  <tr>
   <td><a href="https://registry.terraform.io/search/modules?namespace=imperva&q=dsf-">Imperva Terraform Modules Registry</a> 
   </td>
   <td>
   </td>
  </tr>
  <tr>
   <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7">DSFKit GitHub Repository</a> 
   </td>
   <td>
   </td>
  </tr>
  <tr>
   <td><a href="https://git-scm.com/downloads">Download Git</a>
   </td>
  </tr>
  <tr>
   <td><a href="https://www.terraform.io/downloads">Download Terraform</a>
   </td>
   <td>
Latest Supported Terraform Version: 1.4.x. Using a higher version may result in unexpected behavior or errors.
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform">Requst access to Terraform Cloud account - Request Form</a>
   </td>
   <td>Grants access for a specific e-mail address to eDSF Kit's Terraform Cloud account.
       Required for <a href="https://github.com/imperva/dsfkit/tree/1.4.7#terraform-cloud-deployment-mode">Terraform Cloud Deployment Mode</a>.
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/document/d/1Ci7sghwflPsfiEb7CH79z1bNI74x_lsChE5w_cG4rMs">Request access to DSF installation software - Request Form</a>
   </td>
   <td> Grants access for a specific AWS account to the DSF installation software.
   </td>
  </tr>
</table>

#### Version History
The following table lists the released DSFKit versions, their release date and a high-level summary of each version's content.

<table>
  <tr>
   <td><strong>Date</strong>
   </td>
   <td><strong>Version</strong>
   </td>
   <td><strong>Details</strong>
   </td>
  </tr>
  <tr>
   <td>3 Nov 2022
   </td>
   <td>1.0.0
   </td>
   <td>First release for SEs. Beta.
   </td>
  </tr>
  <tr>
   <td>20 Nov 2022
   </td>
   <td>1.1.0
   </td>
   <td>Second Release for SEs. Beta.
   </td>
  </tr>
  <tr>
   <td>3 Jan 2023
   </td>
   <td>1.2.0
   </td>
   <td>1. Added multi accounts example. <br>2. Changed modules interface.
   </td>
  </tr>
  <tr>
   <td>19 Jan 2023
   </td>
   <td>1.3.4
   </td>
   <td>1. Refactored directory structure. <br>2. Released to terraform registry. <br>3. Supported DSF Hub / Agentless Gateway on RedHat 7 ami. <br>4. Restricted permissions for Sonar installation. <br>5. Added the module's version to the examples.
   </td>
  </tr>
  <tr>
   <td>26 Jan 2023
   </td>
   <td>1.3.5
   </td>
   <td>1. Enabled creating RDS MsSQL with synthetic data for POC purposes. <br>2. Fixed manual and automatic installer machine deployments. 
   </td>
  </tr>
  <tr>
   <td>5 Feb 2023
   </td>
   <td>1.3.6
   </td>
   <td>Supported SSH proxy for DSF Hub / Agentless Gateway in modules: hub, agentless-gw, federation, poc-db-onboarder.
   </td>
  </tr>
  <tr>
   <td>28 Feb 2023
   </td>
   <td>1.3.7
   </td>
   <td>
      1. Added the option to provide a custom security group id for the DSF Hub and the Agentless Gateway via the 'security_group_id' variable.
      <br>2. Restricted network resources and general IAM permissions.
      <br>3. Added a new installation example - single_account_deployment.
      <br>4. Added the minimum required Terraform version to all modules.
      <br>5. Added the option to provide EC2 AMI filter details for the DSF Hub and the Agentless Gateway via the 'ami' variable. 
      <br>6. For user-provided AMI for the DSF node (DSF Hub and the Agentless Gateway) that denies execute access in '/tmp' folder, added the option to specify an alternative path via the 'terraform_script_path_folder' variable.
      <br>7. Passed the password of the DSF node via AWS Secrets Manager.
      <br>8. Added the option to provide a custom S3 bucket location for the Sonar binaries via the 'tarball_location' variable.
      <br>9. Bug fixes.
   </td>
  <tr>
   <td>16 Mar 2023
   </td>
   <td>1.3.9
   </td>
   <td>
      1. Added support for deploying a DSF node on an EC2 without outbound internet access by providing a custom AMI with the required dependencies and creating VPC endpoints.
      <br>2. Replaced the installer machine manual and automatic deployment modes with a new and simplified single installer machine mode.
      <br>3. Added support for storing the Terraform state in an AWS S3 bucket.
      <br>4. Made adjustments to support Terraform version 1.4.0.
   </td>
  </tr>
  <tr>
   <td>27 Mar 2023
   </td>
   <td>1.3.10
   </td>
   <td>
      1. Added support for supplying a custom key-pair for ssh to the DSF Hub and the Agentless Gateway.
      <br>2. Added support for the new Sonar public patch '4.10.0.1'.
   </td>
  </tr>
  </tr>
  <tr>
   <td>3 Apr 2023
   </td>
   <td>1.4.0
   </td>
   <td>
      1. Added support for the new Sonar version '4.11'.
      <br>2. Added support for Agentless Gateway HADR.
   </td>
  </tr>
   <tr>
   <td>13 Apr 2023
   </td>
   <td>1.4.1
   </td>
   <td>
      Bug fixes.
   </td>
  </tr>
  <tr> 
   <td>17 Apr 2023
   </td>
   <td>1.4.2
   </td>
   <td>
      Updated DSFKit IAM required permissions.
   </td>
  </tr>
  <tr>
   <td>20 Apr 2023
   </td>
   <td>1.4.3
   </td>
   <td>
      1. First Alpha deployment of Agent Gateway and MX. It can be used with caution.
      <br>2. Updated DSFKit IAM required permissions. 
   </td>
  </tr>
  <tr>
   <td>2 May 2023
   </td>
   <td>1.4.4
   </td>
   <td>
      1. Minimum supported Sonar version is now 4.11. To deploy earlier versions, work with earlier DSFKit versions.
      <br>2. In the POC examples, onboarded the demo databases to the Agentless Gateway instead of the DSF Hub.
   </td>
  </tr>
  <tr>
   <td>16 May 2023
   </td>
   <td>1.4.5
   </td>
   <td>
      1. Defined separate security groups for the DSF node according to the traffic source type (e.g., web console, Hub).  
      <br>2. Added the option to provide custom secrets for the DSF Hub and the Agentless Gateway.
      <br>3. Updated the POC multi_account_deployment example.
   </td>
  </tr>
  <tr>
   <td>28 May 2023
   </td>
   <td>1.4.6
   </td>
   <td>
      1. Replaced IAM Role variable with instance profile.
      <br>2. Removed usage of AWS provider's default_tags feature.
      <br>3. First Alpha deployment of DRA. It can be used with caution.
      <br>4. Alpha deployment example of full DSF - Sonar, DAM and DRA. It can be used with caution.
   </td>
  </tr>
  <tr>
   <td>11 June 2023
   </td>
   <td>1.4.7
   </td>
   <td>
      1. Triggered the first replication cycle as part of an HADR setup.
      <br>2. Added LVM support (DSF Hub and Agentless GW).
      <br>3. Fixed error while onboarding MSSQL RDS.
   </td>
  </tr>
  <tr>
   <td>14 June 2023
   </td>
   <td>1.4.8
   </td>
   <td>
      1. Fixed typo in the required IAM permissions.
      <br>2. Added support for Terraform version 1.5.0.
      <br>3. Fixed global tags.
   </td>
  </tr>

</table>

# Getting Ready to Deploy

## Choosing the Deployment Mode

DSFKit offers several deployment modes:

* **CLI Deployment Mode:** This mode offers a straightforward deployment option that relies on running a Terraform script on the deployment client's machine which must be a Linux machine.

  For more details, refer to [CLI Deployment Mode](#cli-deployment-mode).
* **Installer Machine Deployment Mode:** This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine which the user creates, instead of on the deployment client's machine. This mode can be used if a Linux machine is not available, or DSFKit cannot be run on the available Linux machine, e.g., since it does not have permissions to access the deployment environment.

  For more details, refer to [Installer Machine Deployment Mode](#installer-machine-deployment-mode).
* **Terraform Cloud Deployment Mode:** This mode makes use of Terraform Cloud, a service that exposes a dedicated UI to create and destroy resources via Terraform.
  This mode can  be used in case we don't want to install any software on the deployment client's machine. It can be used to demo DSF on an Imperva AWS Account or on a customer’s AWS account (if the customer supplies credentials).

  For more details, refer to [Terraform Cloud Deployment Mode](#terraform-cloud-deployment-mode).

The first step in the deployment is to choose the deployment mode most appropriate to you.
If you need more information to decide on your preferred mode, refer to the detailed instructions for each mode [here](#deployment).

## Prerequisites

Before using DSFKit to deploy DSF, it is necessary to satisfy a set of prerequisites.

1. Create an AWS User with secret and access keys which comply with the required IAM permissions (see [IAM Role section](#iam-users-and-roles)).
2. The deployment requires access to the DSF installation software. [Click here to request access](https://docs.google.com/document/d/1Ci7sghwflPsfiEb7CH79z1bNI74x_lsChE5w_cG4rMs).
3. Only if you chose the [CLI Deployment Mode](#cli-deployment-mode), download Git [here](https://git-scm.com/downloads).
4. Only if you chose the [CLI Deployment Mode](#cli-deployment-mode), download Terraform [here](https://www.terraform.io/downloads). It is recommended on MacOS systems to use the "Package Manager" option during installation.
5. Latest Supported Terraform Version: 1.4.x. Using a higher version may result in unexpected behavior or errors.

## Choosing the Example/Recipe that Fits Your Use Case

An important thing to understand about the DSF deployment, is that there are many variations on what can be deployed, 
e.g., with or without DRA, the number of Agentless Gateways, with or without HADR, the number of VPCs, etc.

We provide several of out-of-the-box Terraform recipes we call "examples" which are already configured to deploy common DSF environments.
You can use the example as is, or customize it to accommodate your deployment requirements.

These examples can be found in the <a href="https://github.com/imperva/dsfkit/tree/1.4.7">DSFKit GitHub Repository</a> under the <a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples">examples</a> directory.
Some examples are intended for Lab or POC and others for actual DSF deployments by Professional Services and customers.

For more details about each example, click on the example name.

<table>
   <tr>
      <td><strong>Example</strong>
      </td>
      <td><strong>Purpose</strong>
      </td>
      <td><strong>Description</strong>
      </td>
      <td><strong>Download</strong>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_basic_deployment/README.md">Sonar Basic Deployment</a>
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway, federation, networking and onboarding of a MySQL DB. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_basic_deployment/sonar_basic_deployment.zip">sonar_basic_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_hadr_deployment/README.md">Sonar HADR Deployment</a>
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway, DSF Hub and Agentless Gateway HADR, federation, networking and onboarding of a MySQL DB. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_hadr_deployment/sonar_hadr_deployment.zip">sonar_hadr_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/installation/sonar_single_account_deployment/README.md">Sonar Single Account Deployment</a>
      </td>
      <td>PS/Customer
      </td>
      <td>A DSF deployment with a DSF Hub HADR, an Agentless Gateway and federation. The DSF nodes (Hubs and Agentless Gateway) are in the same AWS account and the same region. It is mandatory to provide as input to this example the subnets to deploy the DSF nodes on.  
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/installation/sonar_single_account_deployment/sonar_single_account_deployment.zip">sonar_single_account_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/installation/sonar_multi_account_deployment/README.md">Sonar Multi Account Deployment</a>
      </td>
      <td>PS/Customer
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway and federation. The DSF nodes (Hub and Agentless Gateway) are in different AWS accounts. It is mandatory to provide as input to this example the subnets to deploy the DSF nodes on. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/installation/sonar_multi_account_deployment/sonar_multi_account_deployment.zip">sonar_multi_account_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dam_basic_deployment/README.md">DAM Basic Deployment</a> (Alpha)
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with an MX, an Agent Gateway, networking and onboarding of an Agent with a randomly selected DB type: PostgreSql, MySql or MariaDB.   
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dam_basic_deployment/dam_basic_deployment.zip">dam_basic_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dra_basic_deployment/README.md">DRA Basic Deployment</a> (Alpha)
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with an DRA Admin, DRA Analytics and networking.   
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dra_basic_deployment/dra_basic_deployment.zip">dra_basic_deployment.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dsf_deployment/README.md">DSF Deployment</a> (Alpha)
      </td>
      <td>Lab/POC
      </td>
      <td>A full DSF deployment with DSF Hub and Agentless Gateways (formerly Sonar), DAM (MX and Agent Gateways), DRA (Admin and DRA Analytics), and Agent and Agentless audit sources.
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/alpha/dsfdeployment/dsf_deployment.zip">dsf_deployment.zip</a>
      </td>
   </tr>
</table>

If you are familiar with Terraform, you can go over the example code and see what it consists of.
The examples make use of the building blocks of the DSFKit - the modules, which can be found in the <a href="https://registry.terraform.io/search/modules?namespace=imperva&q=dsf-">Imperva Terraform Modules Registry</a>. As a convention, the DSFKit modules' names have a 'dsf' prefix.

Feel free to [fill out this form](https://docs.google.com/forms/d/e/1FAIpQLSe3_IoAtuIyLUf9crqXiJwo540iuTZ9l0K1I-uQ-CXRbZL7xA/viewform) if you need help choosing or customizing an example to suit your needs. 

## Installation Software Location and Versioning

When using eDSF Kit there is no need to manually download the DSF installation software, eDSF Kit will do that automatically based on the Sonar, DAM and DRA versions specified in the Terraform example.
In order to be able to download the installation software during deployment, you must request access beforehand. See [Prerequisites](#prerequisites).

The latest DSF version, Q1 2023, is recommended.
This includes the following version of the DSF sub-products:
<table>
  <tr>
    <td><strong>DSF Sub-Product</strong>
    </td>
    <td><strong>Recommended Version</strong>
    </td>
    <td><strong>Supported Versions</strong>
    </td>
  </tr>
  <tr>
    <td>Sonar</td><td>4.11</td><td>4.9 and up 

Restrictions on modules may apply</td>
  </tr>
  <tr>
    <td>DAM</td><td>14.11.1.10</td><td>14.11.1.10

14.7.x.y (LTS)

  </tr>
  <tr>
    <td>DRA</td><td>4.11.0.10.0.7</td><td>4.11.0.10.0.7</td>
  </tr>
</table>

**For example**: examples/poc/sonar_basic_deployment/variables.tf
   ```terraform
   variable "sonar_version" {
       type    = string
       default = "4.11"
   }

   >>>> Change the Sonar version to the one you want to install
   ```

Make sure that the version you are using is supported by all the modules which are part of your deployment.
To see which versions are supported by each module, refer to the specific module's README. 
(For example, [DSF Hub module's README](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest))

# Deployment 

After you have [chosen the deployment mode](#choosing-the-deployment-mode), follow the step-by-step instructions below to ensure a successful deployment. If you have any questions or issues during the deployment process, please contact [Imperva Technical Support](https://support.imperva.com/s/).

## CLI Deployment Mode

This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments.
Terraform CLI uses a bash script and therefore requires a Linux/Mac machine.

The first thing to do in this deployment mode is to [download Terraform ](https://www.terraform.io/downloads).

**NOTE:** Update the values for the required parameters to complete the installation: example_name, aws_access_key_id, aws_secret_access_key and region

1. Download the zip file of the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section) from the <a href="https://github.com/imperva/dsfkit/tree/1.4.7">DSFKit GitHub Repository</a>, e.g., if you choose the "sonar_basic_deployment" example, you should download <a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_basic_deployment/sonar_basic_deployment.zip">sonar_basic_deployment.zip</a>.

2. Unzip the zip file in CLI or using your operating system's UI.
   For example, in CLI:
   ```bash
   unzip sonar_basic_deployment.zip
   
   >>>> Change this command depending on the example you chose
   ```

3. In CLI, navigate to the directory which contains the Terraform files.
   For example:
   ```bash
   cd sonar_basic_deployment
   
   >>>> Change this command depending on the example you chose
   ```

4. Optionally make changes to the example's Terraform code to fit your use case. If you need help doing that, please contact [Imperva Technical Support](https://support.imperva.com/s/).


4. Terraform uses the AWS shell environment for AWS authentication. More details on how to authenticate with AWS are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  \
   For simplicity, in this example we will use environment variables:

    ```bash
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}

    >>>> Fill the values of the access_key, secret_key and region placeholders, e.g., export AWS_ACCESS_KEY_ID=5J5AVVNNHYY4DM6ZJ5N46.
    ```

5. Run:
    ```bash
    terraform init
    ```
6. Run:
    ```bash
    terraform apply -auto-approve
    ```

   This should take about 30 minutes.


7. Depending on your deployment:
   
   To access the DSF Hub, extract the web console admin password and DSF URL using:
    ```bash
    terraform output "web_console_dsf_hub"
    ```
   To access the DAM, extract the web console admin password and DAM URL using:
    ```bash
    terraform output "web_console_dam"
    ```
   To access the DRA Admin, extract the web console admin password and MX URL using:
    ```bash
    terraform output "web_console_dra"
    ```

8. Access the DSF Hub, DAM or DRA web console from the output in the previous step by entering the outputted URL into a web browser, “admin” as the username and the outputted admin_password value. Note, there is no initial login password for DRA.

**The CLI Deployment is now complete and a functioning version of DSF is now available.**

## Installer Machine Deployment Mode

This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine which the user creates, instead of on the deployment client's machine. This mode can be used if a Linux machine is not available, or DSFKit cannot be run on the available Linux machine, e.g., since it does not have permissions to access the deployment environment.

1. In AWS, choose a region for the installer machine while keeping in mind that the machine should have access to the DSF environment that you want to deploy, and preferably be in proximity to it.


2. **Launch an Instance:** Search for RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2 image and click “enter”:<br>![Launch an Instance](https://user-images.githubusercontent.com/87799317/203822848-8dd8705d-3c91-4d7b-920a-b89dd9e0998a.png)


3. Choose the “Community AMI”:<br>![Community AMI](https://user-images.githubusercontent.com/87799317/203825854-99287e5b-2d68-4a65-9b8b-40ae9a49c90b.png)


4. Select t2.medium 'Instance type', or t3.medium if T2 is not available in the region.


5. Create or select an existing 'Key pair' that you will later use to run SSH to the installer machine.


6. In the Network settings panel - make your configurations while keeping in mind that the installer machine should have access to the DSF environment that you want to deploy, and that the deployment's client machine should have access to the installer machine.


7. Expand the “Advanced details” panel:<br>![Advanced details](https://user-images.githubusercontent.com/87799317/203825918-31879c4b-ca61-48e3-a522-c325335c4419.png)


8. Copy and paste the contents of this [bash script](https://github.com/imperva/dsfkit/blob/1.4.7/installer_machine/installer_machine_user_data.sh) into the [User data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) textbox.<br>![User data](https://user-images.githubusercontent.com/87799317/203826003-661c829f-d704-43c4-adb7-854b8008577c.png)


9. Click on **Launch Instance**. At this stage, the installer machine is initializing and downloading the necessary dependencies.


10. When launching is completed, run SSH to the installer machine from the deployment client's machine:
     ```bash
     ssh -i ${key_pair_file} ec2-user@${installer_machine_public_ip}
   
    >>>> Replace the key_pair_file with the name of the file from step 4, and the installer_machine_public_ip with 
         the public IP of the installer machine which should now be available in the AWS EC2 console.
         E.g., ssh -i a_key_pair.pem ec2-user@1.2.3.4
     ```

    **NOTE:** You may need to decrease the access privileges of the key_pair_file in order to be able to use it in for ssh.
    For example: `chmode 400 a_key_pair.pem`


11. Download the zip file of the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section) from the <a href="https://github.com/imperva/dsfkit/tree/1.4.7">DSFKit GitHub Repository</a>, e.g., if you choose the "sonar_basic_deployment" example, you should download <a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/poc/sonar_basic_deployment/sonar_basic_deployment.zip">sonar_basic_deployment.zip</a>.
    Run:
    ```bash
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/poc/sonar_basic_deployment/sonar_basic_deployment.zip
    
    or
    
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/poc/sonar_hadr_deployment/sonar_hadr_deployment.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/installation/sonar_single_account_deployment/sonar_single_account_deployment.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/installation/sonar_multi_account_deployment/sonar_multi_account_deployment.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/alpha/dam_basic_deployment/dam_basic_deployment.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/alpha/dra_basic_deployment/dra_basic_deployment.zip

    or
 
    wget https://github.com/imperva/dsfkit/raw/1.4.7/examples/alpha/dsf_deployment/dsf_deployment.zip
    ```

12. Unzip the zip file:
    ```bash
    unzip sonar_basic_deployment.zip

    >>>> Change this command depending on the example you chose
    ```

13. Continue by following the [CLI Deployment Mode](#cli-deployment-mode) beginning at step 3.

**IMPORTANT:** Do not destroy the installer machine until you are done and have destroyed all other resources. Otherwise, there may be leftovers in your AWS account that will require manual deletion which is a tedious process. For more information see the [Installer Machine Undeployment Mode](#installer-machine-undeployment-mode) section.

**The Installer Machine Deployment is now completed and a functioning version of DSF is now available.**

## Terraform Cloud Deployment Mode

This deployment mode uses the Terraform Cloud service, which allows deploying and managing deployments via a dedicated UI. Deploying the environment is easily triggered by clicking a button within the Terraform interface, which then pulls the required code from the Imperva GitHub repository and automatically runs the scripts remotely. 

This deployment mode can be used to demonstrate DSF in a customer's Terraform Cloud account or the Imperva Terraform Cloud account, which is accessible for internal use (SEs, QA, Research, etc.), and can be used to deploy/undeploy POC environments on AWS accounts owned by Imperva.

 It is required that you have access to a Terraform Cloud account. Any account may be used, whether the account is owned by Imperva or the customer. [Click here to request access to Imperva's Terraform Cloud account](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform).

If you want to use Imperva's Terraform Cloud account, the first thing to do is to request access here:
[Open Terraform Cloud Account - Request Form](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform).
**Our internal Terraform Cloud account can only be used for demo purposes and not for customer deployments**.

**NOTE:** Currently this deployment mode doesn't support customizing the chosen example's code.

1. **Connect to Terraform Cloud:** Connect to the desired Terraform Cloud account, either the internal Imperva account or a customer account if one is available.
2. **Create a new workspace:** Complete these steps to create a new workspace in Terraform Cloud that will be used for the DSF deployment. 
    * Click the **+ New workspace** button in the top navigation bar to open the **Create a new Workspace** page.<br>![New Workspace](https://user-images.githubusercontent.com/52969528/212976777-f3095813-baa6-4ece-aba2-29b39001aa48.png)

    * Choose **Version Control Workflow** from the workflow type options.<br>![Version Control Workflow](https://user-images.githubusercontent.com/87799317/203772173-888eeb65-adc4-4e0b-94ec-daad24532282.png)

    * Choose **github.com/dsfkit** as the version control provider.<br>![github.com/dsfkit](https://user-images.githubusercontent.com/87799317/203773848-9bdae743-2e56-4a5a-9c4c-aaa4812b4d78.png)

    * Choose **imperva/dsfkit** as the repository. <br>
    If this option is not displayed, type imperva/dsfkit in the “Filter” textbox.<br>![imperva/dsfkit](https://user-images.githubusercontent.com/87799317/203773953-69c615db-68d3-4703-a3ef-a7cfab6e3149.png)

    * Name the workspace in the following format: <br>
      ```bash
      dsfkit-${customer_name}-${environment_name}
      
      >>>> Fill the values of the customer_name and environment_name placeholders, e.g., dsfkit-customer1-poc1
      ```

    * Click on the Advanced options button.<br>![Advanced options](https://user-images.githubusercontent.com/52969528/212977394-60f79882-008b-44ef-bb05-9af629b1a88a.png)

    * Enter the path to the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section), e.g., “examples/poc/sonar_basic_deployment”, into the Terraform working directory input field.![Terraform Working Directory](https://user-images.githubusercontent.com/52969528/212981545-31063817-e9ef-43e4-bb9c-b4a8e5391568.png)
      ```
      >>>> Change the directory in the above screenshot depending on the example you chose  
      ```

    * Select the “Auto apply” option as the Apply Method.<br>![Auto apply](https://user-images.githubusercontent.com/87799317/203820284-ea8479f7-b486-4040-8ce1-72c36fd22515.png)

    * To avoid automatic Terraform configuration changes when the GitHub repo updates, set the following values under “Run triggers”:<br>![Run Triggers](https://user-images.githubusercontent.com/52969528/212982564-e12f9b4a-ca3e-480b-9714-76ef69291ee4.png)
      <br>As displayed in the above screenshot, the Custom Regular Expression field value should be “23b82265”.

    * Click “Create workspace” to finish and save the new DSFKit workspace.<br>![Create workspace](https://user-images.githubusercontent.com/52969528/212977895-ad9cdc4c-bf44-4a83-b67e-57e7f7e6e6f7.png)

3. **Add the AWS variables:** The next few steps will configure the required AWS variables.
    * Once the DSFKit workspace is created, click the "Go to workspace overview" button.<br>![Go to Workspace Overview](https://user-images.githubusercontent.com/52969528/212978246-42ce66c1-ffbc-4932-8c0a-4d13188065eb.png)

    * Click on the "Configure Variables" button.<br>![Configure Variables](https://user-images.githubusercontent.com/52969528/212978735-afcbfee8-d524-4b08-8e4f-42a12530f490.png)

    * Add the following workspace variables by entering the name, value, category and sensitivity as listed below. 

        <table>
        <tr>
        <td>
        <strong>Variable Name</strong>
        </td>
        <td><strong>Value</strong>
        </td>
        <td><strong>Category</strong>
        </td>
        <td><strong>Sensitive</strong>
        </td>
        </tr>
        <tr>
        <td>AWS_ACCESS_KEY_ID
        </td>
        <td>Your AWS credentials access key
        </td>
        <td>Environment variable
        </td>
        <td>True
        </td>
        </tr>
        <tr>
        <td>AWS_SECRET_ACCESS_KEY
        </td>
        <td>Your AWS credentials secret key
        </td>
        <td>Environment variable
        </td>
        <td>True
        </td>
        </tr>
        <tr>
        <td>AWS_REGION
        </td>
        <td>The AWS region you wish to deploy into
        </td>
        <td>Environment variable
        </td>
        <td>False
        </td>
        </tr>
        </table>
        <br>

        ![Workspace Variables](https://user-images.githubusercontent.com/52969528/212979637-4f36652d-a18d-40bc-b8ae-bebfe5e8f874.png)
      ```
      >>>> Change the AWS_REGION value in the above screenshot to the AWS region you want to deploy in
      ```

4. **Run the Terraform:** The following steps complete setting up the DSFKit workspace and running the example's Terraform code. 
    * Click on the **Actions** dropdown button from the top navigation bar, and select the "Start new run" option from the list.</br>![Start New Run](https://user-images.githubusercontent.com/52969528/212980571-9071c3e5-400a-42e7-a7d9-5848b8b9fad7.png)

    * Enter a unique, alphanumeric name for the run, and click on the "Start run" button.<br>![Start Run](https://user-images.githubusercontent.com/52969528/212982996-2010be16-79f7-497d-a9c9-13ebc29fa052.png)
      ```
      >>>> Change the "Reason for starting run" value in the above screenshot to a run name of your choosing
      ```
   
    * Wait for the run to complete, it should take about 30 minutes and is indicated by "Apply finished".<br>![Apply Finished](https://user-images.githubusercontent.com/52969528/212989107-46bdd44c-e328-47c0-a478-33d69b3b7c34.png)

5. **Inspect the run result:** These steps provide the necessary information to view the run output, and access the deployed DSF. 
    * Scroll down the "Apply Finished" area to see which resources were created.

    * Scroll to the bottom to find the "State versions created" link which can be helpful to investigate issues.<br>![State Version Created](https://user-images.githubusercontent.com/52969528/212992756-dfd183ac-640e-4891-8875-c1b8683d8d8d.png)

    * Scroll up to view the "Outputs" of the run which should be expanded already. Depending on your deployment, 
      locate the "web_console_dsf_hub", "web_console_dam" or "web_console_dra" JSON object. Copy the "public_url" or "private_url" and "admin_password" fields' values for later use (there is no initial login password for DRA), for example: <br>![Outputs Console](https://user-images.githubusercontent.com/52969528/212992062-d44b9cce-6050-4095-b0d5-ecc0a21954fb.png)
   
    * Enter the "public_url" or "private_url" value you copied into a web browser. For example, enter the "web_console_dsf_hub" URL to access the Imperva Data Security Fabric (DSF) login screen.<br>![login](https://user-images.githubusercontent.com/87799317/203822712-5f1c859f-abff-4e47-92a8-2007015e0272.png)

    * Sonar is installed with a self-signed certificate, as a result, when opening the web page you may see a warning notification. For example, in Google Chrome, click "Proceed to domain.com (unsafe)".
    ![Warning](https://user-images.githubusercontent.com/87799317/203822774-2f4baf1d-a59b-4376-af3a-8654f4d7b22c.png)

    * Enter “admin” into the Username field and the "admin_password" value you copied into the Password field. Click "Sign In".

**The Terraform Cloud Deployment is now complete and a functioning version of DSF is now available.**

# IAM Users and Roles

To be able to create AWS resources inside any AWS Account, you need to provide an AWS User or Role with the required permissions in order to run DSFKit Terraform.
The permissions are separated to different policies. Use the relevant policies according to your needs:

1. For general required permissions such as create an EC2, security group, etc., use the permissions specified here -  [general required permissions](/permissions_samples/GeneralRequiredPermissions.txt).
2. In order to create network resources such as VPC, NAT Gateway, Internet Gateway etc., use the permissions specified here - [create network resources permissions](/permissions_samples/CreateNetworkResourcesPermissions.txt).
3. In order to onboard a MySQL RDS with CloudWatch configured, use the permissions specified here - [onboard MySQL RDS permissions](/permissions_samples/OnboardMysqlRdsPermissions.txt).
4. In order to onboard a MsSQL RDS with audit configured and with synthetic data, use the permissions specified here - [onboard MsSQL RDS with synthetic data permissions](/permissions_samples/OnboardMssqlRdsWithDataPermissions.txt).

Please note that when running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable.</br></br>
**NOTE:** The permissions specified in option 2 are irrelevant for customers who prefer to use their own network objects, such as VPC, NAT Gateway, Internet Gateway, etc.

# Undeployment

Depending on the deployment mode you chose, follow the undeployment instructions of the same mode to completely remove Imperva DSF from AWS.

The undeployment process should be followed whether the deployment was successful or not. 
In case of failure, the Terraform may have deployed some resources before failing, and want these removed.

## CLI Undeployment Mode

1. Navigate to the directory which contains the Terraform files.
   For example:
   ```bash
   cd sonar_basic_deployment
   
   >>>> Change this command depending on the example you chose
   ```
2. Terraform uses the AWS shell environment for AWS authentication. More details on how to authenticate with AWS are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  \
   For simplicity, in this example we will use environment variables:

    ```bash
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}

    >>>> Fill the values of the access_key, secret_key and region placeholders, e.g., export AWS_ACCESS_KEY_ID=5J5AVVNNHYY4DM6ZJ5N46.
    ```
   
3. Run:
    ```bash
    terraform destroy -auto-approve
    ```

## Installer Machine Undeployment Mode

1. Run SSH to installer machine from the deployment client's machine:
    ```bash
    ssh -i ${key_pair_file} ec2-user@${installer_machine_public_ip}
   
   >>>> Fill the values of the key_pair_file and installer_machine_public_ip placeholders  
    ```

2. Continue by following the [CLI Undeployment Mode](#cli-undeployment-mode) steps.


3. Wait for the environment to be destroyed.


4. Terminate the EC2 installer machine via the AWS Console.

## Terraform Cloud Undeployment Mode

1. To undeploy the DSF deployment, click on Settings and find "Destruction and Deletion" from the navigation menu to open the "Destroy infrastructure" page. Ensure that the "Allow destroy plans" toggle is selected, and click on the Queue Destroy Plan button to begin.<br>![Destroy Plan](https://user-images.githubusercontent.com/87799317/203826129-6957bb53-b824-4f7a-8bbd-b44c17a5a3c4.png)

2. The DSF deployment is now destroyed and the workspace may be re-used if needed. If this workspace is not being re-used, it may be removed with “Force delete from Terraform Cloud” that can be found under Settings.<br>![delete](https://user-images.githubusercontent.com/87799317/203826179-de7a6c1d-31a1-419d-9c71-61c96cfb7d2e.png)

**NOTE:** Do not remove the workspace before the deployment is completely destroyed. Doing so may lead to leftovers in your AWS account that will require manual deletion which is a tedious process.

# More Information

Information about additional topics can be found in specific examples' READMEs, when relevant.

For example:  <a href="https://github.com/imperva/dsfkit/tree/1.4.7/examples/installation/sonar_single_account_deployment/README.md">Sonar Single Account Deployment</a>

These topics include:
- Storing Terraform state in S3 bucket
- Working with DSF Hub and Agentless Gateway without outbound internet access

# Troubleshooting 

Review the following issues and troubleshooting remediations. 


<table>
  <tr>
   <td><strong>Title</strong>
   </td>
   <td><strong>Error message</strong>
   </td>
   <td><strong>Remediation</strong>
   </td>
  </tr>
  <tr>
   <td>Vpc quota exceeded
   </td>
   <td>error creating EC2 VPC: VpcLimitExceeded: The maximum number of VPCs has been reached
   </td>
   <td>Remove unneeded vpc via <a href="https://console.aws.amazon.com/vpc/home#vpcs:">vpc dashboard</a>, or increase vpc quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas/L-F678F1CE">this page</a> and run again
   </td>
  </tr>
  <tr>
   <td>EIP quota exceeded
   </td>
   <td>Error creating EIP: AddressLimitExceeded: The maximum number of addresses has been reached
   </td>
   <td>Remove unneeded elastic ip via <a href="https://console.aws.amazon.com/ec2/home#Addresses:">this dashboard</a>, or increase elastic ip quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-0263D0A3">this page</a> and run again
   </td>
  </tr>
  <tr>
   <td>AWS internal glitches
   </td>
   <td>Error: creating EC2 Instance: InvalidNetworkInterfaceID.NotFound: The networkInterface ID 'eni-xxx does not exist
   </td>
   <td>Rerun “terraform apply” to overcome aws internal sync issues
   </td>
  </tr>
  <tr>
   <td>AWS Option Groups quota exceeded
   </td>
   <td>Error: "Cannot create more than 20 option groups". Remediation similar to the other exceeded errors
   </td>
   <td>Remove unneeded Option Groups <a href="https://console.aws.amazon.com/rds/home#option-groups-list:">here</a>, or increase elastic ip quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/rds/quotas/L-9FA33840">this page</a> and run again
   </td>
  </tr>
</table>
