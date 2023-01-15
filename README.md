# Data Security Fabric (DSF) Kit Installation Guide
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

# About This Guide

This guide is intended for Imperva Sales Engineers (SE) for the purpose of Proof-of-Concept (POC) demonstrations that deploy the Imperva Data Security Fabric (DSF) Kit solution.
```
NOTE: This guide is for INTERNAL USE ONLY, to be used by in-house staff for POCs and demos of the new DSF installation. The current focus is on Sonar parts only.
```

**Typographical Conventions**

This guide uses several text styles for an enhanced readability and several call-out features. Learn about their aspect and meaning from the table below.

<table>
  <tr>
   <td><strong>Convention</strong>
   </td>
   <td><strong>Description</strong>
   </td>
  </tr>
  <tr>
   <td>Code Input
   </td>
   <td>
   
   ```
   Code will be called out using this font for easy identification of required user input. 
   ```

   </td>
  </tr>
  <tr>
   <td>Hyperlinks
   </td>
   <td>Clickable urls embedded within the guide are blue and underlined. E.g. <a href="http://www.imperva.com">www.imperva.com</a>
   </td>
  </tr>
</table>


**Document Scope**

This document covers the following main topics. Additional guides are referenced throughout this document, as listed in the Quick Links reference section below, and are available for more information on each respective topic. 

* How to install Imperva’s Data Security Fabric (DSF) Kit with step-by-step instructions. 
* Verification of a successful installation via logging output. 
* How to uninstall DSFKit with step-by-step instructions.

**Quick Links**

This guide references the following information and links, most of which are available via the Document Portal on the Imperva website: [https://docs.imperva.com](https://docs.imperva.com). For a quick reference, the name and link for each URL is listed below. (Login required)


<table>
  <tr>
   <td><strong>Document Name</strong>
   </td>
  </tr>
  <tr>
   <td>DSF Components Overview:
<ul>

<li><a href="https://docs.imperva.com/howto/d27b25ee/">Sonar</a>

<li><a href="https://docs.imperva.com/howto/1cc28a13">DAM</a>

<li><a href="https://docs.imperva.com/howto/fc0e6cc8">DRA</a>
</li>
</ul>
   </td>
  </tr>
  <tr>
   <td><a href="https://git-scm.com/downloads">Download Git</a>
   </td>
  </tr>
  <tr>
   <td><a href="https://www.terraform.io/downloads">Download Terraform</a>
   </td>
  </tr>
  <tr>
   <td><a href="https://github.com/imperva/dsfkit">DSFKit GitHub Repo </a> 
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform">Open Terraform Cloud Account - Request Form</a>
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform">Open TAR AWS S3 Bucket - Request Form</a>
   </td>
  </tr>
</table>


**Document Revisions**
The following table lists the most recent document revisions, dates of publication, a high-level summary, and descriptions of the updated information. 


<table>
  <tr>
   <td><strong>Publication Date</strong>
   </td>
   <td><strong>DSF Version</strong>
   </td>
   <td><strong>Summarized Description of Updates</strong>
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
</table>



# Getting Ready to Deploy  

The Imperva DSFKit enables you to easily install a working instance of the DSF Portal, providing access to the full suite of DSF products including Sonar, DAM, and DRA. The DSFKit can be easily installed by following the steps in this guide and is currently available for POC scenarios on AWS only. 

Before installing DSFKit, it is necessary to complete the following steps:

1. Create an AWS User with secret and access keys which comply with the required IAM permissions (see [IAM Role section](#iam-roles)).
2. Deployment requires access to the tarball containing Sonar binaries. The tarball is located in a dedicated AWS Bucket owned by Imperva. Click [here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform) to request access to download this file.  
3. UI Installation Mode requires access to a Terraform Cloud Platform account. Any  account may be used, whether the account is owned by Imperva or the customer. Click [here](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform) to request access to Imperva's Terraform Account.
4. [Download Git](https://git-scm.com/downloads).
5. [Download Terraform](https://www.terraform.io/downloads). It is recommended on MacOS systems to use the "PACKAGE MANAGER" option during installation.

```
NOTE: Note: It may take several hours for access to be granted to AWS and Terraform in Steps 2 and 3.
```

## Binaries Location and Versioning

When using DSFKit there is no need to manually download the DSF binaries, DSFKit will do that automatically based on the Sonar version specified in the Terraform recipe.

**File**: examples/poc/basic_deployment/variables.tf
```bash
 variable "sonar_version" {
    type    = string
    default = "4.10"
}
```

```
NOTE: DSFKit version 1.2.0 is available and supports Sonar version 4.10.
```

# DSFKit Installation 

DSFKit is the official Terraform toolkit designed to automate the deployment and maintenance of Imperva's Data Security Fabric (DSF). DSFKit offers two installation methods:

* **UI Installation Mode:** This method makes use of Terraform Cloud, a service that exposes a dedicated UI to create and destroy resources via Terraform.** **This method is used in cases where we don't want to install any software on the client's machine. This can be used to demo DSF on an Imperva AWS Account or on a customer’s AWS account (if the customer supplies credentials).  \

* **CLI Installation Mode:** This method offers a straightforward installation option that relies on entering and running a Terraform script. This method is recommended when the customer wants to install the demo environment on their own machine, or when using the Terraform Cloud is not possible.

Please select the most appropriate method and follow the step-by-step instructions to ensure a successful installation. If you have any questions or issues during the installation process, please contact [Imperva Technical Support](https://support.imperva.com/s/). 

## UI Installation Mode

The User Interface (UI) installation mode uses the Terraform Cloud (TF Cloud) service, which allows installing and managing deployments via a dedicated UI. Deploying the environment is easily triggered by clicking a button within the Terraform interface, which then pulls the required code from the Imperva GitHub repository and automatically runs the scripts remotely. 

[Open Terraform Cloud Account - Request Form](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform)

```
NOTE: The UI Installation Mode can be used to demo DSF in a customer's Terraform account or the Imperva Terraform account, which is accessible for internal use (SEs, QA, Research, etc') and can be used to deploy/destroy demo environments on AWS accounts owned by Imperva.
```

Please complete the following step-by-step installation instructions provided below and contact [Imperva Technical Support](https://support.imperva.com/s/) with any issues or questions.

### UI Installation Steps

Follow these instructions to install DSFKit via the UI Installation Mode:

1. **Connect to Terraform Cloud:** Connect to the desired Terraform cloud account, either the internal Imperva account or a customer account if one is available.
2. **Create a New Workspace:** Complete these steps to create a new workspace in Terraform cloud that will be used for the DSFKit deployment. 
    * Click the **+ New Workspace** button in the top navigation bar to open the Create a new Workspace page.<br>![New Workspace](https://user-images.githubusercontent.com/87799317/203771096-f79f6621-9d29-41e8-a05c-a0d09cf319b4.png)
    * Choose **Version Control Workflow** from the workflow type options.<br>![Version Control Workflow](https://user-images.githubusercontent.com/87799317/203772173-888eeb65-adc4-4e0b-94ec-daad24532282.png)

    * Choose **github.com/dsfkit** as the version control provider.<br>![github.com/dsfkit](https://user-images.githubusercontent.com/87799317/203773848-9bdae743-2e56-4a5a-9c4c-aaa4812b4d78.png)

    * Choose **imperva/dsfkit** as the repository. <br>
    If this option is not displayed, type imperva/dsfkit in the “Filter” textbox.<br>![imperva/dsfkit](https://user-images.githubusercontent.com/87799317/203773953-69c615db-68d3-4703-a3ef-a7cfab6e3149.png)

    * Name the workspace in the following format: <br>
    Example:  
    ```bash
        dsfkit-[NAME_OF_CUSTOMER]-[NAME_OF_ENVIRONMENT]
    ```

    * Click on the Advanced options button.<br>![Advanced options](https://user-images.githubusercontent.com/87799317/203774205-54db54e9-9e16-481b-8225-3ecee32fb148.png)

    * Enter “examples/poc/basic_deployment” into the Terraform working directory input field. To understand what the basic_deployment example consists of or the create a custom demo, please see more details in the [Customizing Demos - Examples/Recipes](#customizing-demos---examplesrecipes) section.<br>![deploy/examples/basic_deployment](https://user-images.githubusercontent.com/87799317/203820129-39804a8a-eb90-451c-bc66-b5adb4cb90f3.png)
    
    * Select the “Auto apply” option as the Apply Method.<br>![Auto apply](https://user-images.githubusercontent.com/87799317/203820284-ea8479f7-b486-4040-8ce1-72c36fd22515.png)

    * To avoid automatic Terraform configuration changes when the GitHub repo updates, set the following values under “Run triggers”:<br>![Run triggers](https://user-images.githubusercontent.com/87799317/203820430-573edeb8-4698-4a03-bcc6-1f560963aeff.png)<br>
    As displayed in the above screenshot, the Custom Regular Expression field value should be “23b82265”.

    * Click “Create workspace” to finish and save the new DSFKit workspace.<br>![Create workspace](https://user-images.githubusercontent.com/87799317/203820500-ec61fec1-8f8a-47b5-bd6f-10261ba60f51.png)

3. **Add the AWS Variables:** The next few steps will configure the required AWS variables.
    * Once Terraform has finished creating the DSFKit workspace, click the Workspace Overview button to continue.<br>![Workspace Overview](https://user-images.githubusercontent.com/87799317/203820579-c3ede713-4536-4d49-aae3-e148bd6030c1.png)

    * Click on the Configure Variables button.<br>![Configure Variables](https://user-images.githubusercontent.com/87799317/203820695-330bd204-4b57-470d-b321-901c71fe0785.png)

    * Add the following workspace variables by entering the name, value, and category as listed below. 

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
        <td>The AWS access key
        </td>
        <td>env
        </td>
        <td>True
        </td>
        </tr>
        <tr>
        <td>AWS_SECRET_ACCESS_KEY
        </td>
        <td>The AWS access key
        </td>
        <td>env
        </td>
        <td>True
        </td>
        </tr>
        <tr>
        <td>AWS_REGION
        </td>
        <td>The region you wish to deploy into
        </td>
        <td>env
        </td>
        <td>False
        </td>
        </tr>
        </table>
        <br>

        ![Workspace Variables](https://user-images.githubusercontent.com/87799317/203822280-1d6f4f62-b8f6-46f2-99a4-265daba8744a.png)

4. **Run the Imperva GitHub Code:** The following steps complete setting up the DSFKit workspace and run the Imperva GitHub code. 
    * Click on the **Actions** dropdown button from the top navigation bar, and select the Start **New Run** option from the list.![alt_text](https://user-images.githubusercontent.com/87799317/203822365-6fb16b0e-e37a-401e-91da-37d4be5866a8.png)

    * Enter a unique alphanumeric name for the run, and click on the **Start Run** button. As the run completes, Terraform will show what resources it has created and what resources are currently provisioned.<br>![Start Run](https://user-images.githubusercontent.com/87799317/203822418-f3be0996-aab9-48eb-ace2-14c4d4aadee1.png)

5. **Complete the Workspace Deployment:** These steps provide the necessary information to view and access the newly created workspace, and a fully functioning instance of Imperva’s DSF. 
    * Once the run has completed, click to expand the **Apply Finished** section.<br>![Apply Finished](https://user-images.githubusercontent.com/87799317/203822491-5713a8ec-1e9e-4025-a47c-94325dfe0e76.png)

    * Scroll to the bottom and expand the **Outputs** section to find the State Versions Created link and the auto-generated password under “admin-password” which will be  used to log into the DSF Portal in a future step.<br>![Outputs](https://user-images.githubusercontent.com/87799317/203822561-250f5ffe-1d02-4b3d-9fbd-263c9d59dc5b.png)

    * Expand outputs to view the environment settings and locate the **dsf_hub_web_console**.<br>![dsf_hub_web_console_url](https://user-images.githubusercontent.com/87799317/203822608-2de059a5-e3af-49a7-944b-2ba390517d16.png)

    * Copy the **dsf_hub_web_console** URL into a web browser to open the Imperva Data Security Fabric (DSF) login screen.<br>![login](https://user-images.githubusercontent.com/87799317/203822712-5f1c859f-abff-4e47-92a8-2007015e0272.png)

    ```
    NOTE: Sonar is installed with a self-signed certificate, as result when opening the web page you may see a warning notification. Please click "Proceed to domain.com (unsafe)".
    ```
    ![warning](https://user-images.githubusercontent.com/87799317/203822774-2f4baf1d-a59b-4376-af3a-8654f4d7b22c.png)

    * Enter “admin” into the username field and the auto-generated password from the previous step to find the unmasked “admin_password” output. Click **Sign In**.

**The UI Installation is now complete and a functioning version of DSF is now available.**

## Local CLI Installation Mode

This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments. Terraform CLI uses a bash script and therefore requires a Linux/Mac machine. To deploy DSFKit using the CLI installation mode, please complete the following steps:

1. [Download Git ](https://git-scm.com/downloads)
2. [Download Terraform ](https://www.terraform.io/downloads)

### Local CLI Installation Steps

Follow these instructions to install DSFKit via the local CLI mode.

```
NOTE: Update the values for the required parameters to complete the installation: example_name, aws_access_key_id, aws_secret_access_key and region
```

1. Git clone dfskit:
    ```bash
    git clone https://github.com/imperva/dsfkit.git
    git -C dsfkit checkout tags/${version}
    ```

2. Navigate to the directory "examples":
    ```bash
    cd dsfkit/examples/${example_name}
    ```


    DSFKit arrives with a built-in example “basic_deployment” which should meet most POC requirements. See “[Customizing Demos](#customizing-demos---examplesrecipes)” to understand the environment created with the “basic_deployment” example and to learn how to create specific requirements if needed.<br>For simplicity we will use the following:
    ```bash
    cd dsfkit/examples/poc/basic_deployment
    ```

3. Terraform uses the AWS shell environment for AWS authentication. More details on how to authenticate with AWS are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  \
For simplicity, in this example we will use environment variables:

    ```bash
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}
    ```


4. Run:
    ```bash
    terraform init
    ```
5. Run:
    ```bash
    terraform apply -auto-approve
    ```

    This should take about 30 minutes.

6. Extract the web console admin password and DSF URL using:
    ```bash
    terraform output "dsf_hub_web_console"
    ```
7. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step. 

**The CLI Installation is now complete and a functioning version of DSF is now available.**

## Installer Machine Mode

If a Linux machine is not available or DSFKit cannot be run locally, Imperva supports deployments via a DSFKit Installer Machine on AWS. This dedicated machine acts as a “bastion server”, and the user only needs to create a t2.medium EC2 machine and OS: RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2.

This can be done either manually or via an automated process. Select a method below and follow the instructions:


### Manual Installer Machine

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

```
NOTES: 

1. In this example 'web_console_cidr' was set to 0.0.0.0/0. This configuration opens the Hub web console as a public web site. If needed, specify a more restricted IP and CIDR range.
2. The link to the GitHub repo can be updated and supplied by you, in the case of custom demos and examples. See Customizing Demos section for more information.
3. DO NOT DESTROY THE INSTALLER MACHINE UNTIL YOU ARE DONE AND HAVE DESTROYED ALL OTHER RESOURCES. OTHERWISE THERE WILL BE UNDELETABLE RESOURCES. For more information see Uninstalling Installer Machine Mode section.
```

7. When installation is done extract the web console password and DSF URL using:
    1. ```bash
        cd /dsfkit/examples/<example_name>
        ```
    2. ```bash
        terraform output "dsf_hub_web_console"
        ```
8. Access the DSF Portal by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password generated in the previous step.  \

### Automated Installer Machine

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

```
NOTE: At this stage the Installer Machine is initializing. At its initialization it will automatically create all the other resources (Hub, GWs etc).

DO NOT DESTROY THE INSTALLER MACHINE UNTIL YOU ARE DONE AND DESTROYED ALL THE OTHER RESOURCES. OTHERWISE YOU WILL LEAVE UNDELETABLE RESOURCES for more information see  Uninstalling Installer Machine Mode section
```

6. After the first phase of the installation is completed, it outputs the following ssh commands, for example:

    ```
    installer_machine_ssh_command = "ssh -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17"
    logs_tail_ssh_command = "ssh -o StrictHostKeyChecking='no' -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17 -C 'sudo tail -f /var/log/user-data.log'"
    ```


7. The second and last phase of the installation runs in the background. To follow it and know when it is completed, run 
    ```
    logs_tail_ssh_command
    ```
    which appears in the first phase output.
8. After the installation is completed, run ssh to the installer machine using the `installer_machine_ssh_command` which appears in the first phase output.
9. ```bash
    cd /dsfkit/examples/<example_name>
    ```
10. Extract the web console admin password and DSF URL using:
    ```bash
    terraform output "dsf_hub_web_console"
    ```
11. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step. 

```
NOTE: The Terraform script is OS-Safe, as it doesn't run any bash script.
```

# Customizing Demos - Examples/Recipes 

DSFKit ships 2 built-in examples/recipes which are already configured to deploy a basic Sonar environment:

1. “basic_deployment” recipe, consist of:
    1. New VPC
    2. 1 Hub
    3. 1 GW
    4. Federation
    5. Creation of a new “Demo DB”
    6. Auto configuration of new “Demo DB” to enable native audit
    7. Onboarding database into Sonar

2. “hadr_deployment” recipe, consist of:
    1. New VPC
    2. 1 Primary Hub
    3. 1 Secondary Hub
    4. 1 GW
    5. Federation
    6. Hub HADR

It is also possible to accommodate varying system requirements and deployments.  To customize the demo, please complete the following steps:

1. Fork dsfkit from git. 

2. In the Git account assemble a new Terraform recipe that meets the necessary requirements. 

    ```bash
    cd examples/<YOUR CUSTOM EXAMPLE>
    terraform init
    terraform appy -auto-approve
    ```

# IAM Roles

To be able to create AWS resources inside any AWS Account, you need to provide an AWS User with the required permissions in order to run DSFKit Terraform.
The permissions are separated to 3 different policies. Use the relevant policies according to your needs:

1. For general required permissions such as create an EC2, security group, etc., use the permissions specified here -  [general required permissions](/permissions_samples/GeneralRequiredPermissions.txt).
2. In order to create network resources such as VPC, NAT Gateway, Internet Gateway etc., use the permissions specified here - [create network resources permissions](/permissions_samples/CreateNetworkResourcesPermissions.txt).
3. In order to onboard a MySQL RDS with CloudWatch configured, use the permissions specified here - [onboard MySQL RDS permissions](/permissions_samples/OnboardMysqlRdsPermissions.txt).

```
NOTE: The permissions specified in option 2 are irrelevant for customers who prefer to use their own network objects, such as VPC, NAT Gateway, Internet Gateway, etc.
```

# DSFKit Uninstallation

Please select the most appropriate method to uninstall and destroy the workspace.

## UI Mode

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.



1. To destroy the environment, click on Settings and find Destruction and Deletion from the navigation menu to open the Destroy Infrastructure page. Ensure that the Allow Destroy Plans toggle is selected, and click on the Queue Destroy Plan button to begin.<br>![Destroy Plan](https://user-images.githubusercontent.com/87799317/203826129-6957bb53-b824-4f7a-8bbd-b44c17a5a3c4.png)

2. The installed environment is now destroyed and the workspace may be re-used if needed. If this workspace is not being re-used, it may be removed with “Force delete from Terraform Cloud” that can be found under Settings.<br>![delete](https://user-images.githubusercontent.com/87799317/203826179-de7a6c1d-31a1-419d-9c71-61c96cfb7d2e.png)

    ```
    NOTE: Do not remove the workspace before the deployment is completely destroyed. Doing so may lead to leftovers in your AWS account that will require manual deletion which is a tedious process.
    ```

## Local CLI Mode 

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.

1. cd into the installed “example”:
    ```bash
    cd examples/<example_name>
    ```
2. Run: 
    ```bash
    terraform destroy -auto-approve
    ```

## Installer Machine Mode 

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.

1. ssh into the “Installer Machine”.
2. cd into the installed “example”: ```bash
    cd /dsfkit/examples/<example_name>
    ```
3. Run:
    ```bash
    sudo su
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}
    terraform destroy -auto-approve
    ```

4. Wait for the environment to be destroyed.


#### Automated Installer Machine

1. Exit from the “Installer Machine”.
2. On the local machine, cd into installer_machine/.
3. ```bash
    terraform destroy -auto-approve
    ```

#### Manual Installer Machine

1. Destroy the Installer Machine (dsf_installer_machine) and the security group (dsf_installer_machine-sg) via AWS UI Console.


# Troubleshooting 

Please review the following issues and troubleshooting remediations. 


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
