# Data Security Fabric (DSF) Kit Deployment Guide
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

# DSFKit

Imperva DSFKit is the official Terraform toolkit designed to automate the deployment of Imperva's Data Security Fabric (DSF Hub & Agentless Gateway) (formerly Sonar).
The DSF Hub can be easily deployed by following the steps in this guide which are currently available for deployments on AWS only.

In the near future, DSFKit will enable you to deploy the full suite of DSF products, including DAM and DRA, and will support the other major public clouds.

# About This Guide

#### Audience

Currently, this guide is for internal use only.

It is intended for Imperva Sales Engineers (SE) for the purpose of Proof-of-Concept (POC) demonstrations.

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
   This fond will be used to denote code blocks, commands or user input. 
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
   <a href="https://docs.imperva.com/howto/ed55ac24">Sonar v4.10</a>

   <a href="https://docs.imperva.com/howto/66707580">DAM v14.10</a>

   <a href="https://docs.imperva.com/howto/4e487f3c">DRA v4.10</a>
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
   <td><a href="https://github.com/imperva/dsfkit/tree/1.3.4">DSFKit GitHub Repository</a> 
   </td>
   <td>
   </td>
  </tr>
  <tr>
   <td><a href="https://www.terraform.io/downloads">Download Terraform</a>
   </td>
   <td>
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform">Open Terraform Cloud Account - Request Form</a>
   </td>
   <td>Grants access for a specific e-mail address to Imperva's Terraform Cloud account.
       Required for <a href="https://github.com/imperva/dsfkit/tree/dev#terraform-cloud-deployment-mode">Terraform Cloud Deployment Mode</a>
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform">Open TAR AWS S3 Bucket - Request Form</a>
   </td>
   <td> Grants access for a specific AWS account to Imperva's AWS S3 bucket where Sonar's installation tarball can be downloaded
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
   <td>18 Jan 2023
   </td>
   <td>1.3.4
   </td>
   <td>1. Refactored directory structure. <br>2. Released to terraform registry. <br>3. Supported hub/gw on RedHat 7 ami. <br>4. Restricted permissions for Sonar installation. <br>5. Added the module's version to the examples.
   </td>
  </tr>
  
</table>

# Getting Ready to Deploy

Before using DSFKit to deploy DSF, it is necessary to complete the following steps:

1. Create an AWS User with secret and access keys which comply with the required IAM permissions (see [IAM Role section](#iam-roles)).
2. The deployment requires access to the tarball containing the Sonar binaries. The tarball is located in a dedicated AWS S3 bucket owned by Imperva. 
   Click [here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform) to request access to download this file.  
3. [Terraform Cloud Deployment Mode](#terraform-cloud-deployment-mode) requires access to a Terraform Cloud account. Any  account may be used, whether the account is owned by Imperva or the customer. 
   Click [here](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform) to request access to Imperva's Terraform Cloud account.
4. [Download Terraform](https://www.terraform.io/downloads). It is recommended on MacOS systems to use the "Package Manager" option during installation.


**NOTE:** It may take several hours for the access to be granted to AWS and Terraform Cloud in Steps 2 and 3.

## Sonar Binaries Location and Versioning

When using DSFKit there is no need to manually download the DSF binaries, DSFKit will do that automatically based on the Sonar version specified in the Terraform example recipe.

**For example**: examples/poc/basic_deployment/variables.tf
   ```terraform
   variable "sonar_version" {
       type    = string
       default = "4.10"
   }

   >>>> Change the Sonar version to the one you want to install
   ```

Make sure that the Sonar version you are using is supported by all the modules which are part of your deployment.
To see which Sonar versions are supported by each module, refer to the specific module's README. 
(For example, [Hub module's README](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest))

## Choosing the Example/Recipe that Fits Your Use Case

An important thing to understand about the deployment, is that it begins with choosing a Terraform recipe that we call "example" and using it to deploy DSF, with or without customizations to fit your specific use case.
To see the available examples, refer to [Out-of-the-box Examples](#out-of-the-box-examples).   

Assuming you are familiar with Terraform, you can go over the example code and see what it consists of.
The examples make use of the building blocks of the DSFKit - the modules, which can be found in the <a href="https://registry.terraform.io/search/modules?namespace=imperva&q=dsf-">Imperva Terraform Modules Registry</a>. As a convention, the DSFKit modules' names have a 'dsf' prefix.

You can use the example as is, or customize it to accommodate varying system requirements and deployments. 
You can also start from scratch, but the recommendation is to start from an example and make changes to it if necessary.

# Deployment 

DSFKit offers several deployment modes:

* **CLI Deployment Mode:** This mode offers a straightforward deployment option that relies on running a Terraform script on the deployment client's machine.

  For more details, refer to [CLI Deployment Mode](#cli-deployment-mode).
* **Terraform Cloud Deployment Mode:** This mode makes use of Terraform Cloud, a service that exposes a dedicated UI to create and destroy resources via Terraform. 
    This mode is used in cases where we don't want to install any software on the deployment client's machine. This can be used to demo DSF on an Imperva AWS Account or on a customer’s AWS account (if the customer supplies credentials).

  For more details, refer to [Terraform Cloud Deployment Mode](#terraform-cloud-deployment-mode).
* **Installer Machine Deployment Mode:** This mode can be used if a client machine is not available or DSFKit cannot be run on it. In this mode, the deployment is done via a DSFKit Installer Machine on AWS. This dedicated machine acts as a “bastion server”, and the user only needs to create an EC2 machine and run the Terraform on it. This mode has two options:
  * Manual: The user manually creates the EC2 machine.
  * Automated: The user runs a Terraform script which automatically creates the EC2 machine.

  For more details, refer to [Installer Machine Deployment Mode](#installer-machine-deployment-mode).

Choose the most appropriate mode to you and follow the step-by-step instructions to ensure a successful deployment. If you have any questions or issues during the deployment process, please contact [Imperva Technical Support](https://support.imperva.com/s/). 

## CLI Deployment Mode

This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments.
Terraform CLI uses a bash script and therefore requires a Linux/Mac machine.

The first thing to do in this deployment mode is to [download Terraform ](https://www.terraform.io/downloads).

### CLI Deployment Steps

**NOTE:** Update the values for the required parameters to complete the installation: example_name, aws_access_key_id, aws_secret_access_key and region

1. Download the zip file of the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section) from the <a href="https://github.com/imperva/dsfkit/tree/1.3.4">DSFKit GitHub Repository</a>, e.g., if you choose the "basic_deployment" example, you should download <a href="https://github.com/imperva/dsfkit/tree/1.3.4/examples/poc/basic_deployment/basic_deployment.zip">basic_deployment.zip</a>.

2. Unzip the zip file and navigate to the innermost directory which contains the Terraform files.
   For example:
   ```bash
   cd examples/poc/basic_deployment
   
   >>>> Change this command depending on the example you chose
   ```

3. Optionally make changes to the example's Terraform code to fit your use case.


4. Terraform uses the AWS shell environment for AWS authentication. More details on how to authenticate with AWS are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  \
   For simplicity, in this example we will use environment variables:

    ```bash
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}

    >>>> Fill the values of the access_key, secret_key and region placeholders
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


7. Extract the web console admin password and DSF URL using:
    ```bash
    terraform output "dsf_hub_web_console"
    ```
8. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step.

**The CLI Deployment is now complete and a functioning version of DSF is now available.**

## Terraform Cloud Deployment Mode

This deployment mode uses the Terraform Cloud service, which allows deploying and managing deployments via a dedicated UI. Deploying the environment is easily triggered by clicking a button within the Terraform interface, which then pulls the required code from the Imperva GitHub repository and automatically runs the scripts remotely. 

This deployment mode can be used to demonstrate DSF in a customer's Terraform Cloud account or the Imperva Terraform Cloud account, which is accessible for internal use (SEs, QA, Research, etc.), and can be used to deploy/undeploy POC environments on AWS accounts owned by Imperva.

If you want to use Imperva's Terraform Cloud account, the first thing to do is to request access here:
[Open Terraform Cloud Account - Request Form](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform)

**NOTE:** Currently this deployment mode doesn't support customizing the chosen example's code.

### Terraform Cloud Deployment Steps

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

    * Enter the path to the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section), e.g., “examples/poc/basic_deployment”, into the Terraform working directory input field.![Terraform Working Directory](https://user-images.githubusercontent.com/52969528/212981545-31063817-e9ef-43e4-bb9c-b4a8e5391568.png)
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
   
    * Wait for the run to complete. This is indicated by "Apply finished".<br>![Apply Finished](https://user-images.githubusercontent.com/52969528/212989107-46bdd44c-e328-47c0-a478-33d69b3b7c34.png)

5. **Inspect the run result:** These steps provide the necessary information to view the run output, and access the deployed DSF. 
    * Scroll down the "Apply Finished" area to see which resources were created.

    * Scroll to the bottom to find the "State versions created" link which can be helpful to investigate issues.<br>![State Version Created](https://user-images.githubusercontent.com/52969528/212992756-dfd183ac-640e-4891-8875-c1b8683d8d8d.png)

    * Scroll up to view the "Outputs" of the run which should be expanded already, and locate the "dsf_hub_web_console" JSON object. Copy the "public_url" and "admin_password" fields' values for later use.<br>![Outputs Console](https://user-images.githubusercontent.com/52969528/212992062-d44b9cce-6050-4095-b0d5-ecc0a21954fb.png)
   
    * Enter the "public_url" value you copied into a web browser to access the Imperva Data Security Fabric (DSF) login screen.<br>![login](https://user-images.githubusercontent.com/87799317/203822712-5f1c859f-abff-4e47-92a8-2007015e0272.png)

    * Sonar is installed with a self-signed certificate, as a result, when opening the web page you may see a warning notification. For example, in Google Chrome, click "Proceed to domain.com (unsafe)".
    ![Warning](https://user-images.githubusercontent.com/87799317/203822774-2f4baf1d-a59b-4376-af3a-8654f4d7b22c.png)

    * Enter “admin” into the Username field and the "admin_password" value you copied into the Password field. Click "Sign In".

**The Terraform Cloud Deployment is now complete and a functioning version of DSF is now available.**

## Installer Machine Deployment Mode

If a Linux machine is not available or DSFKit cannot be run locally, Imperva supports deployments via a DSFKit Installer Machine on AWS. This dedicated machine acts as a “bastion server”, and the user only needs to create a t2.medium EC2 machine and OS: RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2.

This can be done either manually or via an automated process. Select your preferred method and follow the instructions below.

**NOTE:** Currently this deployment mode doesn't support customizing the chosen example's code.

### Manual Installer Machine Deployment Mode

Complete these steps to manually create an installer machine:

1. **Launch an Instance:** Search  for RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2 Image and click “enter”:<br>![Launch an Instance](https://user-images.githubusercontent.com/87799317/203822848-8dd8705d-3c91-4d7b-920a-b89dd9e0998a.png)

2. Choose the “Community AMI”:<br>![Community AMI](https://user-images.githubusercontent.com/87799317/203825854-99287e5b-2d68-4a65-9b8b-40ae9a49c90b.png)

3. Expand the “Advanced details” panel:<br>![Advanced details](https://user-images.githubusercontent.com/87799317/203825918-31879c4b-ca61-48e3-a522-c325335c4419.png)

4. Scroll down to find the “User data” input and paste [this bash script](https://github.com/imperva/dsfkit/blob/master/installer_machine/prepare_installer.tpl) into the “User data” textbox.<br>![User data](https://user-images.githubusercontent.com/87799317/203826003-661c829f-d704-43c4-adb7-854b8008577c.png)

5. Update the following parameter values in the bash script: 
    1. example_name (e.g., basic_deployment)
    2. aws_access_key_id
    3. aws_secret_access_key
    4. region
    5. web_console_cidr

6. Click on **Launch Instance**. At this stage the Installer Machine is initializing and will automatically create all of the other necessary resources (Hub, GWs etc). View the progress logs by SSH into the machine and view the “user-data” logs:
    ```bash
    tail -f /var/logs/user-data.log
    ```

   **NOTES:**

   * In this example, 'web_console_cidr' was set to 0.0.0.0/0. This configuration opens the Hub web console as a public web site. It is recommended to specify a more restricted IP and CIDR range.
   * IMPORTANT: Do not destroy the installer machine until you are done and have destroyed all other resources. Otherwise, there may be leftovers in your AWS account that will require manual deletion which is a tedious process. For more information see the [Manual Installer Machine Undeployment Mode](#manual-installer-machine-undeployment-mode) section.


7. When the deployment is done extract the web console password and DSF URL using:
    1. ```bash
       cd dsfkit/examples/${example_name}
       
       >>>> Use the name of the example you chose
       ```
    2. ```bash
        terraform output "dsf_hub_web_console"
        ```
8. Access the DSF Portal by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password generated in the previous step.

**The Manual Installer Machine Deployment is now complete and a functioning version of DSF is now available.**

### Automated Installer Machine Deployment Mode

In case you don’t want to manually create the Installer Machine, you can automate the creation of the Installer Machine. DSFKit exposes a dedicated Terraform example that automatically creates the installer machine with the “user-data”.  Complete these steps to automate the creation of an installer machine:
<br><br>
To use the Terraform installer example follow the following step:

1. ```bash
    git clone https://github.com/imperva/dsfkit.git
    git -C dsfkit checkout tags/${version}
    ```
2. ```bash
    cd dsfkit/installer_machine
    ```
3. ```bash
    terraform init
    ```
4. ```bash
    terraform apply -auto-approve
    ```
5. This script will prompt you to input the aws_access_key, aws_secret_key and aws_region parameters.

   **NOTES:**

   * At this stage the Installer Machine is initializing. During its initialization, it will automatically create all the other resources (Hub, GWs etc).
   * IMPORTANT: Do not destroy the installer machine until you are done and have destroyed all other resources. Otherwise, there may be leftovers in your AWS account that will require manual deletion which is a tedious process. For more information see the [Automated Installer Machine Undeployment Mode](#automated-installer-machine-undeployment-mode) section.
   
6. After the first phase of the installation is completed, it outputs the following ssh commands, for example:

    ```bash
    installer_machine_ssh_command = "ssh -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17"
    logs_tail_ssh_command = "ssh -o StrictHostKeyChecking='no' -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17 -C 'sudo tail -f /var/log/user-data.log'"
    ```

7. The second and last phase of the installation runs in the background. To follow it and know when it is completed, run:
    ```bash
    logs_tail_ssh_command
    ```
    which appears in the first phase output.
8. After the installation is completed, run ssh to the installer machine using the `installer_machine_ssh_command` which appears in the first phase output.
9. ```bash
    cd dsfkit/examples/${example_name}
    
    >>>> Use the name of the example you chose
    ```
10. Extract the web console admin password and DSF URL using:
    ```bash
    terraform output "dsf_hub_web_console"
    ```
11. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step. 

   **NOTE:** The Terraform script is OS-Safe, as it doesn't run any bash script.

**The Automated Installer Machine Deployment is now complete and a functioning version of DSF is now available.**

# Out-of-the-box Examples

DSFKit provides a number of out-of-the-box examples which are already configured to deploy a basic Sonar environment.

These examples can be found in the <a href="https://github.com/imperva/dsfkit/tree/1.3.4">DSFKit GitHub Repository</a> under the <a href="https://github.com/imperva/dsfkit/tree/1.3.4/examples">examples</a> directory.
Some examples are intended for POC and others for actual DSF deployments by Professional Services and customers.

For POC:

1. “basic_deployment” example, consist of:
    1. New VPC
    2. 1 Hub
    3. 1 GW
    4. Federation
    5. Creation of a new “Demo DB”
    6. Auto configuration of new “Demo DB” to enable native audit
    7. Onboarding database into Sonar

2. “hadr_deployment” example, consist of:
    1. New VPC
    2. 1 Primary Hub
    3. 1 Secondary Hub
    4. 1 GW
    5. Federation
    6. Hub HADR     
    7. Creation of a new “Demo DB”
    8. Auto configuration of new “Demo DB” to enable native audit
    9. Onboarding database into Sonar

For Professional Services and customers:

3. "multi_account_deployment" example, consist of:
    1. 1 Hub
    2. 1 GW
    3. Federation

Download a zip file of the example code using these links:

* <a href="https://github.com/imperva/dsfkit/tree/1.3.4/examples/poc/basic_deployment/basic_deployment.zip">Basic Deployment</a>
* <a href="https://github.com/imperva/dsfkit/tree/1.3.4/examples/poc/hadr_deployment/hadr_deployment.zip">HADR Deployment</a>
* <a href="https://github.com/imperva/dsfkit/tree/1.3.4/examples/installation/multi_account_deployment/multi_account_deployment.zip">Multi Account Deployment</a>

# IAM Roles

To be able to create AWS resources inside any AWS Account, you need to provide an AWS User with the required permissions in order to run DSFKit Terraform.
The permissions are separated to 3 different policies. Use the relevant policies according to your needs:

1. For general required permissions such as create an EC2, security group, etc., use the permissions specified here -  [general required permissions](/permissions_samples/GeneralRequiredPermissions.txt).
2. In order to create network resources such as VPC, NAT Gateway, Internet Gateway etc., use the permissions specified here - [create network resources permissions](/permissions_samples/CreateNetworkResourcesPermissions.txt).
3. In order to onboard a MySQL RDS with CloudWatch configured, use the permissions specified here - [onboard MySQL RDS permissions](/permissions_samples/OnboardMysqlRdsPermissions.txt).

**NOTE:** The permissions specified in option 2 are irrelevant for customers who prefer to use their own network objects, such as VPC, NAT Gateway, Internet Gateway, etc.

# Undeployment

Depending on the deployment mode you chose, follow the undeployment instructions of the same mode to completely remove Imperva DSF from AWS.

## CLI Undeployment Mode

1. ```bash
   cd dsfkit/examples/${example_name}
   
   >>>> Use the name of the example you chose
   ```

2. Run:
    ```bash
    terraform destroy -auto-approve
    ```

## Terraform Cloud Undeployment Mode

1. To undeploy the DSF deployment, click on Settings and find "Destruction and Deletion" from the navigation menu to open the "Destroy infrastructure" page. Ensure that the "Allow destroy plans" toggle is selected, and click on the Queue Destroy Plan button to begin.<br>![Destroy Plan](https://user-images.githubusercontent.com/87799317/203826129-6957bb53-b824-4f7a-8bbd-b44c17a5a3c4.png)

2. The DSF deployment is now destroyed and the workspace may be re-used if needed. If this workspace is not being re-used, it may be removed with “Force delete from Terraform Cloud” that can be found under Settings.<br>![delete](https://user-images.githubusercontent.com/87799317/203826179-de7a6c1d-31a1-419d-9c71-61c96cfb7d2e.png)

**NOTE:** Do not remove the workspace before the deployment is completely destroyed. Doing so may lead to leftovers in your AWS account that will require manual deletion which is a tedious process.

## Installer Machine Undeployment Mode

### Manual Installer Machine Undeployment Mode

1. ssh into the Installer Machine.


2. ```bash
   cd dsfkit/examples/${example_name}
   
   >>>> Use the name of the example you chose
   ```
3. Run:
    ```bash
    sudo su
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}
    terraform destroy -auto-approve
   
    >>>> Fill the values of the access_key, secret_key and region variables
    ```

4. Wait for the environment to be destroyed.

5. Destroy the Installer Machine (dsf_installer_machine) and the security group (dsf_installer_machine-sg) via AWS Console.

### Automated Installer Machine Undeployment Mode

1. Exit from the Installer Machine.


2. On the local machine:
   ```bash
   cd installer_machine
   ```
3. Run:
    ```bash
    terraform destroy -auto-approve
    ```

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
