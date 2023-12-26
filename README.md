# Data Security Fabric (DSF) Kit Deployment and Upgrade Guide
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

# eDSF Kit

Imperva eDSF Kit is a Terraform toolkit designed to automate the deployment and upgrade of Imperva's Data Security Fabric.

## eDSF Kit Deployment

eDSF Kit enables you to deploy the full suite of the DSF sub-products - DSF Hub & Agentless Gateway (formerly Sonar), 
DAM (Data Activity Monitoring) MX and Agent Gateway and DRA (Data Risk Analytics) Admin and Analytics. 

Currently, eDSF Kit supports deployments on AWS and Azure cloud providers. In the near future, it will support other major public clouds, 
on-premises (vSphere) and hybrid environments.

## eDSF Kit Upgrade

eDSF Kit enables you to upgrade DSF Hubs and Agentless Gateways (formerly Sonar) which are deployed on AWS.

In the future, eDSF Kit will enable you to upgrade the full suite of the DSF sub-products, including DAM and DRA, and 
will support other major clouds, on-premises (vSphere) and hybrid environments.

# About This Guide

#### Audience

This guide is intended for Imperva Sales Engineers (SE) for the purpose of Proof-of-Concept (POC) demonstrations and preparing for these demonstrations, aka, Lab.

It is also intended for Imperva Professional Services (PS) and customers for actual deployments of DSF.

#### Purpose and Scope

This guide covers the following main topics. Additional guides are referenced throughout, as listed in the Quick Links section below.

* How to deploy Imperva’s Data Security Fabric (DSF) with step-by-step instructions.
* How to verify that the deployment was successful using the eDSF Kit output.
* How to undeploy DSF with step-by-step instructions.
* How to upgrade Imperva’s Data Security Fabric (DSF) Hub and Agentless Gateway, with step-by-step instructions.

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
   <a href="https://docs.imperva.com/howto/115c754e">Sonar v4.13</a>

   <a href="https://docs.imperva.com/howto/3f513830">DAM v14.13</a>

   <a href="https://docs.imperva.com/howto/71799f9d">DRA v4.13</a>
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
   <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3">eDSF Kit GitHub Repository</a> 
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
Latest Supported Terraform Version: 1.5.x. Using a higher version may result in unexpected behavior or errors.
   </td>
  </tr>
  <tr>
   <td><a href="https://docs.google.com/document/d/1Ci7sghwflPsfiEb7CH79z1bNI74x_lsChE5w_cG4rMs">Request access to DSF installation software on AWS - Request Form</a>
   </td>
   <td> Grants access for a specific AWS account to the DSF installation software.
   </td>
  </tr>
</table>

#### Version History

The following table lists the _latest_ eDSF Kit releases, their release date and a high-level summary of the release's content.

[Previous releases](https://github.com/imperva/dsfkit/blob/1.6.0/PREVIOUS_RELEASES.md)

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
      <br>2. Added the option to provide custom secrets for the DSF Hub and Agentless Gateway.
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
   <td>11 Jun 2023
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
   <td>14 Jun 2023
   </td>
   <td>1.4.8
   </td>
   <td>
      1. Fixed typo in the required IAM permissions.
      <br>2. Added support for Terraform version 1.5.0.
      <br>3. Fixed global tags.
   </td>
  </tr>
  <tr>
   <td>4 Jul 2023
   </td>
   <td>1.5.0
   </td>
   <td>
      1. Added support for the new DSF version '4.12'.
      <br>2. Released full DSF POC example. 
      <br>3. Bug fixes. 
   </td>
  </tr>
  <tr>
   <td>18 Jul 2023
   </td>
   <td>1.5.1
   </td>
   <td>
      1. Released full DSF installation example.
      <br>2. Added support for DAM activation code in addition to the already supported option of a license file.
      <br>3. Added security groups samples to the documentation.
      <br>4. Improvements and bug fixes. 
   </td>
  </tr>
  <tr>
   <td>1 Aug 2023
   </td>
   <td>1.5.2
   </td>
   <td>
      1. Added DSF instances' required IAM permissions samples to the documentation.
      <br>2. Improvements and bug fixes.
   </td>
  </tr>
  <tr>
   <td>16 Aug 2023
   </td>
   <td>1.5.3
   </td>
   <td>
      Improvements and bug fixes.
   </td>
  </tr>
  <tr>
   <td>11 Sep 2023
   </td>
   <td>1.5.4
   </td>
   <td>
      Improvements and bug fixes.
   </td>
  </tr>
  <tr>
   <td>27 Sep 2023
   </td>
   <td>1.5.5
   </td>
   <td>
      1. Azure Alpha release. It can be used with caution.
      <br/>2. Renamed DSF Hub and Agentless Gateway terminology from "primary" and "secondary" to "main" and "DR".
      <br/>3. Improvements and bug fixes.
   </td>
  </tr>
  <tr>
   <td>15 Oct 2023
   </td>
   <td>1.5.6
   </td>
   <td>
      1. Sonar upgrade Alpha release. It can be used with caution.
      <br/>2. Added support for Terraform version 1.6.x.
   </td>
  </tr>
  <tr>
   <td>24 Oct 2023
   </td>
   <td>1.5.7
   </td>
   <td>
      1. Added the option to provide a custom installation base directory for the DSF Hub and Agentless Gateway via the 'base_directory' variable.
      <br/>2. Updated the Sonar upgrade Alpha release.
   </td>
  </tr>
  <tr>
   <td>6 Nov 2023
   </td>
   <td>1.6.0
   </td>
   <td>
      1. Sonar upgrade Beta release.
      <br/>2. Added automatic association between the DSF Hub and the DRA Admin and Analytics. As a result of this association, 
         the DRA sends its security issues to the DSF Hub, and the DSF Hub sends its security issues and audit from agent 
         and agentless sources to the DRA.
      <br/>3. Added the option to provide a URL to download the DSF Hub and Agentless Gateway tarball via the 'tarball_url' variable.
      <br/>4. Added the option to deploy the Agentless Gateway in a public subnet via the 'use_public_ip' variable.
      <br/>5. Added the option to provide a different IP for federation via the 'dsf_hub_federation_ip' and 'dsf_gw_federation_ip' variables. 
   </td>
  </tr>
  <tr>
    <td>14 Nov 2023
    </td>
    <td>1.7.0
    </td>
    <td>
       Sonar deployment on Azure Beta release.
    </td>
  </tr>
  <tr>
    <td>22 Nov 2023
    </td>
    <td>1.7.1
    </td>
    <td>
       Improvements and bug fixes.
    </td>
  </tr>
  <tr>
    <td>12 Dec 2023
    </td>
    <td>1.7.2
    </td>
    <td>
       Improvements and bug fixes.
    </td>
  </tr>
  <tr>
    <td>26 Dec 2023
    </td>
    <td>1.7.3
    </td>
    <td>
       Improvements and bug fixes.
    </td>
  </tr>

</table>

# Getting Ready to Deploy

## Choosing the Deployment Mode

eDSF Kit offers several deployment modes:

* **CLI Deployment Mode:** This mode offers a straightforward deployment option that relies on running a Terraform script on the user's computer which must be a Linux/Unix machine, e.g, Mac.

  For more details, refer to [CLI Deployment Mode](#cli-deployment-mode).
* **Installer Machine Deployment Mode:** This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine that the user launches, instead of on their computer. This mode can be used if a Linux/Unix machine is not available, or eDSF Kit cannot be run on the available Linux/Unix machine, e.g., since it does not have permission or network access to the deployment environment, or if the user doesn't want to install additional software on their computer.

  For more details, refer to [Installer Machine Deployment Mode](#installer-machine-deployment-mode).
* **Terraform Cloud Deployment Mode:** This mode makes use of Terraform Cloud, a service that exposes a dedicated UI to create and destroy resources via Terraform.
  This mode can  be used for purposes similar to the Installer Machine Deployment Mode, but it is usually used by advanced users.

  For more details, refer to [Terraform Cloud Deployment Mode](#terraform-cloud-deployment-mode).

The first step in the deployment is to choose the deployment mode most appropriate to you.
If you need more information to decide on your preferred mode, refer to the detailed instructions for each mode [here](#deployment).

## Deployment Prerequisites

Before using eDSF Kit to deploy DSF, it is necessary to satisfy a set of prerequisites.

### General Prerequisites

1. Only if you chose the [CLI Deployment Mode](#cli-deployment-mode), install [Git](https://git-scm.com).
2. Only if you chose the [CLI Deployment Mode](#cli-deployment-mode), install [Terraform](https://www.terraform.io). It is recommended on MacOS systems to use the "Package Manager" option during installation.
3. Latest Supported Terraform Version: 1.6.x. Using a higher version may result in unexpected behavior or errors.
4. [jq](https://jqlang.github.io/jq/) - Command-line JSON processor.
5. [curl](https://curl.se/) - Command-line tool for transferring data.

### AWS Prerequisites

1. Create an AWS User with secret and access keys which comply with the required IAM permissions (see [IAM Permissions for Running eDSF Kit section](#iam-permissions-for-running-edsf-kit)).
2. The deployment requires access to the DSF installation software. [Click here to request access](https://docs.google.com/document/d/1Ci7sghwflPsfiEb7CH79z1bNI74x_lsChE5w_cG4rMs).

### Azure Prerequisites

1. [establish an Azure App Registration](https://learn.microsoft.com/en-us/azure/healthcare-apis/register-application) and [assign it the necessary role](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-portal?tabs=delegate-condition) 
   for the associated subscription. Note, Assign the Owner role to the app registration on a temporary basis. More specific permissions will be provided in the future.
2. The deployment requires access to the Sonar binaries. Establish an Azure Storage account along with a container, and proceed to upload the Sonar binaries to this storage location as a blob.


## Choosing the Example/Recipe that Fits Your Use Case

An important thing to understand about the DSF deployment, is that there are many variations on what can be deployed, 
e.g., with or without DRA, the number of Agentless Gateways, with or without HADR, the number of VPCs, etc.

We provide several of out-of-the-box Terraform recipes we call "examples" which are already configured to deploy common DSF environments.
You can use the example as is, or customize it to accommodate your deployment requirements.

These examples can be found in the <a href="https://github.com/imperva/dsfkit/tree/1.7.3">eDSF Kit GitHub Repository</a> under the <a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples">examples</a> directory.
Some examples are intended for Lab or POC and others for actual DSF deployments by Professional Services and customers.

For more details about each example, click on the example name.

### AWS Examples

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
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_basic_deployment/README.md">Sonar Basic Deployment</a>
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway, federation, networking and onboarding of a MySQL DB. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_basic_deployment/sonar_basic_deployment_1_7_3.zip">sonar_basic_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_hadr_deployment/README.md">Sonar HADR Deployment</a>
      </td>
      <td>Lab/POC
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway, DSF Hub and Agentless Gateway HADR, federation, networking and onboarding of a MySQL DB. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_hadr_deployment/sonar_hadr_deployment_1_7_3.zip">sonar_hadr_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/sonar_single_account_deployment/README.md">Sonar Single Account Deployment</a>
      </td>
      <td>PS/Customer
      </td>
      <td>A DSF deployment with a DSF Hub HADR, an Agentless Gateway and federation. The DSF nodes (Hubs and Agentless Gateway) are in the same AWS account and the same region. It is mandatory to provide as input to this example the subnets to deploy the DSF nodes on.  
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/sonar_single_account_deployment/sonar_single_account_deployment_1_7_3.zip">sonar_single_account_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/sonar_multi_account_deployment/README.md">Sonar Multi Account Deployment</a>
      </td>
      <td>PS/Customer
      </td>
      <td>A DSF deployment with a DSF Hub, an Agentless Gateway and federation. The DSF nodes (Hub and Agentless Gateway) are in different AWS accounts. It is mandatory to provide as input to this example the subnets to deploy the DSF nodes on. 
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/sonar_multi_account_deployment/sonar_multi_account_deployment_1_7_3.zip">sonar_multi_account_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/dsf_deployment/README.md">DSF Deployment</a>
      </td>
      <td>Lab/POC
      </td>
      <td>A full DSF deployment with DSF Hub and Agentless Gateways (formerly Sonar), DAM (MX and Agent Gateways), DRA (Admin and DRA Analytics), and Agent and Agentless audit sources.
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/dsf_deployment/dsf_deployment_1_7_3.zip">dsf_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/dsf_single_account_deployment/README.md">DSF Single Account Deployment</a>
      </td>
      <td>PS/Customer
      </td>
      <td>A full DSF deployment with DSF Hub and Agentless Gateways (formerly Sonar), DAM (MX and Agent Gateways) and DRA (Admin and DRA Analytics).
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/dsf_single_account_deployment/dsf_single_account_deployment_1_7_3.zip">dsf_single_account_deployment_1_7_3.zip</a>
      </td>
   </tr>
   <tr>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/sonar_upgrade/README.md">Sonar Upgrade (Alpha)</a>
      </td>
      <td>All
      </td>
      <td>Upgrade of DSF Hub and Agentless Gateway (formerly Sonar).
      </td>
      <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/sonar_upgrade/sonar_upgrade_1_7_3.zip">sonar_upgrade_1_7_3.zip</a>
      </td>
   </tr>
</table>

### Azure Examples

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
     <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/azure/poc/dsf_deployment/README.md">DSF Deployment</a>
     </td>
     <td>Lab/POC
     </td>
     <td>A DSF deployment with a DSF Hub, an Agentless Gateway, DSF Hub and Agentless Gateway HADR, federation and networking.
     </td>
     <td><a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/dsf_deployment/dsf_deployment_1_7_3.zip">dsf_deployment_1_7_3.zip</a>
     </td>
  </tr>
</table> 
   

If you are familiar with Terraform, you can go over the example code and see what it consists of.
The examples make use of the building blocks of the eDSF Kit - the modules, which can be found in the <a href="https://registry.terraform.io/search/modules?namespace=imperva&q=dsf-">Imperva Terraform Modules Registry</a>. As a convention, the eDSF Kit modules' names have a 'dsf' prefix.

Fill out the [eDSF Kit pre-deployment questionnaire](https://forms.gle/CNMhdTuymYi4n7zB9) google form if you need help choosing or customizing an example to fit your use case. 

## Installation Software Location and Versioning

When using eDSF Kit, there is no need to manually download the DSF installation software, eDSF Kit will do that automatically based on the Sonar, DAM and DRA versions specified in the Terraform example.
In order to be able to download the installation software during deployment, you must request access beforehand. See [Deployment Prerequisites](#deployment-prerequisites).

This includes the following version of the DSF sub-products:
<table>
  <tr>
    <td><strong>DSF Sub-Product</strong>
    </td>
    <td><strong>Default Version</strong>
    </td>
    <td><strong>Supported Versions</strong>
    </td>
  </tr>
  <tr>
    <td>Sonar</td><td>4.13.0.10</td><td>4.9 and up 

Restrictions on modules may apply</td>
  </tr>
  <tr>
    <td>DAM</td><td>14.13.1.10</td><td>14.11.1.10 and up

14.7.x.y (LTS)

  </tr>
  <tr>
    <td>DRA</td><td>4.13.0.10</td><td>4.11.0.10 and up</td>
  </tr>
</table>

Relevant variables are:
   ```terraform
   variable "sonar_version" {
       type    = string
   }

   variable "dam_version" {
       type    = string
   }

   variable "dra_version" {
       type    = string
   }
   ```

When specifying Sonar and DRA versions, both long and short version formats are supported, for example, 4.12.0.10 or 4.12. The short format maps to the latest patch.

When specifying a DAM version, only long format is supported.


Make sure that the version you are using is supported by all the modules which are part of your deployment.
To see which versions are supported by each module, refer to the specific module. 
(For example, [DSF Hub module](https://registry.terraform.io/modules/imperva/dsf-hub/aws/latest))

# Deployment 

After you have [chosen the deployment mode](#choosing-the-deployment-mode), follow the step-by-step instructions below to ensure a successful deployment. If you have any questions or issues during the deployment process, please contact [Imperva Technical Support](https://support.imperva.com/s/).

## CLI Deployment Mode

This mode offers a straightforward deployment option that relies on running a Terraform script on the user's computer which must be a Linux/Unix machine, e.g, Mac.
This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments.

1. Download the zip file of the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section) from the <a href="https://github.com/imperva/dsfkit/tree/1.7.3">eDSF Kit GitHub Repository</a>, e.g., if you choose the "sonar_basic_deployment" example, you should download <a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_basic_deployment/sonar_basic_deployment.zip">sonar_basic_deployment.zip</a>.

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


5. Terraform leverages the cloud provider's shell environment for authentication. For AWS, refer to the [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html),
   and for Azure, refer to the [Azure CLI Configuration Guide](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli). In this example, we'll use environment variables for simplicity.

   - AWS environment variables

        ```bash
        export AWS_ACCESS_KEY_ID=${access_key}
        export AWS_SECRET_ACCESS_KEY=${secret_key}
        export AWS_REGION=${region}
    
        >>>> Fill the values of the access_key, secret_key and region placeholders, e.g., export AWS_ACCESS_KEY_ID=5J5AVVNNHYY4DM6ZJ5N46.
        ```
    
   - Azure environment variables

        ```bash
        export ARM_TENANT_ID=${tenant_id}
        export ARM_SUBSCRIPTION_ID=${subscription_id}
        export ARM_CLIENT_ID=${client_id}
        export ARM_CLIENT_SECRET=${client_secret}
    
        >>>> Fill the values of the tenant_id, subscription_id, client_id and client_secret placeholders, e.g., export ARM_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.
        ```

6. Run:
    ```bash
    terraform init
    ```
7. Run:
    ```bash
    terraform apply
    ```

   This should take about 30 minutes.


8. Depending on your deployment:
   
   To access the DSF Hub, extract the web console admin password and DSF URL using:
    ```bash
    terraform output "web_console_dsf_hub"
    ```
   To access the DAM, extract the web console admin password and DAM URL using:
    ```bash
    terraform output "web_console_dam"
    ```
   To access the DRA Admin, extract the web console admin password and DRA URL using:
    ```bash
    terraform output "web_console_dra"
    ```

9. Access the DSF Hub, DAM or DRA web console from the output in the previous step by entering the outputted URL into a web browser, “admin” as the username and the outputted admin_password value. Note, there is no initial login password for DRA.

**The CLI Deployment is now completed and a functioning version of DSF is now available.**

## Installer Machine Deployment Mode

This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine that the user launches, instead of on their computer.
This mode can be used if a Linux/Unix machine is not available, or eDSF Kit cannot be run on the available Linux/Unix machine, e.g., since it does not have permission or network access to the deployment environment, or if the user doesn't want to install additional software on their computer.

**NOTE:** The steps provided below are specific to deployment in an AWS environment. For deployment in an Azure environment, it is necessary to [create an Azure virtual machine instance based on Linux/Unix](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-portal?tabs=ubuntu).

1. In AWS, choose a region for the installer machine while keeping in mind that the machine should have access to the DSF environment that you want to deploy, and preferably be in proximity to it.


2. **Launch an Instance:** Use the _RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2_ community AMI or similar.


3. Select t2.medium 'Instance type', or t3.medium if T2 is not available in the region.


4. Create or select an existing 'Key pair' that you will later use to run SSH to the installer machine.


5. In the Network settings panel - make your configurations while keeping in mind that the installer machine should have access to the DSF environment that you want to deploy, and that your computer should have access to the installer machine.


6. In the “Advanced details” panel, copy and paste the contents of this [bash script](https://github.com/imperva/dsfkit/blob/1.7.3/installer_machine/installer_machine_user_data.sh) into the [User data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) textbox.


7. Click on **Launch Instance**. At this stage, the installer machine is initializing and downloading the necessary dependencies.


8. When launching is completed, run SSH to the installer machine from your computer:
     ```bash
     ssh -i ${key_pair_file} ec2-user@${installer_machine_public_ip}
   
    >>>> Replace the key_pair_file with the name of the file from step 4, and the installer_machine_public_ip with 
         the public IP of the installer machine which should now be available in the AWS EC2 console.
         E.g., ssh -i a_key_pair.pem ec2-user@1.2.3.4
     ```

    **NOTE:** You may need to decrease the access privileges of the key_pair_file in order to be able to use it in for ssh.
    For example: `chmode 400 a_key_pair.pem`


9. Download the zip file of the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section) from the <a href="https://github.com/imperva/dsfkit/tree/1.7.3">eDSF Kit GitHub Repository</a>, e.g., if you choose the "sonar_basic_deployment" example, you should download <a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/poc/sonar_basic_deployment/sonar_basic_deployment.zip">sonar_basic_deployment.zip</a>.
    Run:
    ```bash
    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/poc/sonar_basic_deployment/sonar_basic_deployment_1_7_3.zip
    
    or
    
    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/poc/sonar_hadr_deployment/sonar_hadr_deployment_1_7_3.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/installation/sonar_single_account_deployment/sonar_single_account_deployment_1_7_3.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/installation/sonar_multi_account_deployment/sonar_multi_account_deployment_1_7_3.zip
    
    or

    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/poc/dsf_deployment/dsf_deployment_1_7_3.zip
    
    or
 
    wget https://github.com/imperva/dsfkit/raw/1.7.3/examples/aws/installation/dsf_single_account_deployment/dsf_single_account_deployment_1_7_3.zip
    ```

10. Continue by following the [CLI Deployment Mode](#cli-deployment-mode) beginning at step 2.

**IMPORTANT:** Do not destroy the installer machine until you are done and have destroyed all other resources. Otherwise, there may be leftovers in your AWS account that will require manual deletion which is a tedious process. For more information see the [Installer Machine Undeployment Mode](#installer-machine-undeployment-mode) section.

**The Installer Machine Deployment is now completed and a functioning version of DSF is now available.**

## Terraform Cloud Deployment Mode

This deployment mode uses the Terraform Cloud service, which allows deploying and managing deployments via a dedicated UI. Deploying the environment is easily triggered by clicking a button within the Terraform interface, which then pulls the required code from the Imperva GitHub repository and automatically runs the scripts remotely. 

This deployment mode can be used to demonstrate DSF in a customer's Terraform Cloud account or the Imperva Terraform Cloud account, which is accessible for internal use (SEs, QA, Research, etc.), and can be used to deploy/undeploy POC environments on AWS accounts owned by Imperva.

It is required that you have access to a Terraform Cloud account. 

If you want to use Imperva's Terraform Cloud account, contact Imperva's Technical Support.

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

    * Enter the path to the example you've chosen (See the [Choosing the Example/Recipe that Fits Your Use Case](#choosing-the-examplerecipe-that-fits-your-use-case) section), e.g., “examples/aws/poc/sonar_basic_deployment”, into the Terraform working directory input field.![Terraform Working Directory](https://github-production-user-asset-6210df.s3.amazonaws.com/87799317/252918341-edfcf6a6-c782-4863-9c55-100f25e680ed.png)
      ```
      >>>> Change the directory in the above screenshot depending on the example you chose  
      ```

    * Select the “Auto apply” option as the Apply Method.<br>![Auto apply](https://user-images.githubusercontent.com/87799317/203820284-ea8479f7-b486-4040-8ce1-72c36fd22515.png)

    * To avoid automatic Terraform configuration changes when the GitHub repo updates, set the following values under “Run triggers”:<br>![Run Triggers](https://user-images.githubusercontent.com/52969528/212982564-e12f9b4a-ca3e-480b-9714-76ef69291ee4.png)
      <br>As displayed in the above screenshot, the Custom Regular Expression field value should be “23b82265”.

    * Click “Create workspace” to finish and save the new eDSF Kit workspace.<br>![Create workspace](https://user-images.githubusercontent.com/52969528/212977895-ad9cdc4c-bf44-4a83-b67e-57e7f7e6e6f7.png)

3. **Add the AWS variables:** The next few steps will configure the required AWS variables.
    * Once the eDSF Kit workspace is created, click the "Go to workspace overview" button.<br>![Go to Workspace Overview](https://user-images.githubusercontent.com/52969528/212978246-42ce66c1-ffbc-4932-8c0a-4d13188065eb.png)

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

    **NOTE:** The workspace variables mentioned above are tailored for deployment in an AWS environment. For deployment in an Azure environment, it is necessary to include distinct workspace variables, and these will be addressed in a future release.

4. **Run the Terraform:** The following steps complete setting up the eDSF Kit workspace and running the example's Terraform code. 
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
      locate the "web_console_dsf_hub", "web_console_dam" or "web_console_dra" JSON object. Copy the "public_url" or "private_url" and "admin_password" fields' values for later use (there is no initial login password for DRA), for example: <br>![Outputs Console](https://github-production-user-asset-6210df.s3.amazonaws.com/52969528/252985761-7a6b034c-3fc9-43c7-955a-6c3444fa4a78.png)
   
    * Enter the "public_url" or "private_url" value you copied into a web browser. For example, enter the "web_console_dsf_hub" URL to access the Imperva Data Security Fabric (DSF) login screen.<br>![login](https://user-images.githubusercontent.com/87799317/203822712-5f1c859f-abff-4e47-92a8-2007015e0272.png)

    * Sonar is installed with a self-signed certificate, as a result, when opening the web page you may see a warning notification. For example, in Google Chrome, click "Proceed to domain.com (unsafe)".
    ![Warning](https://user-images.githubusercontent.com/87799317/203822774-2f4baf1d-a59b-4376-af3a-8654f4d7b22c.png)

    * Enter “admin” into the Username field and the "admin_password" value you copied into the Password field. Click "Sign In".

**The Terraform Cloud Deployment is now complete and a functioning version of DSF is now available.**

# IAM Permissions

## IAM Permissions for Running eDSF Kit

### IAM Permissions for AWS 

To be able to create AWS resources inside any AWS Account, you need to provide an AWS User or Role with the required permissions in order to run eDSF Kit Terraform.
The permissions are separated to different policies. Use the relevant policies according to your needs:

1. For general required permissions such as create an EC2, security group, etc., use the permissions specified here -  [general required permissions](/permissions_samples/GeneralRequiredPermissions.txt).
2. In order to create network resources such as VPC, NAT Gateway, Internet Gateway etc., use the permissions specified here - [create network resources permissions](/permissions_samples/CreateNetworkResourcesPermissions.txt).
3. In order to onboard a MySQL RDS with CloudWatch configured, use the permissions specified here - [onboard MySQL RDS permissions](/permissions_samples/OnboardMysqlRdsPermissions.txt).
4. In order to onboard a MsSQL RDS with audit configured and with synthetic data, use the permissions specified here - [onboard MsSQL RDS with synthetic data permissions](/permissions_samples/OnboardMssqlRdsWithDataPermissions.txt).

**NOTE:** When running the deployment with a custom 'deployment_name' variable, you should ensure that the corresponding condition in the AWS permissions of the user who runs the deployment reflects the new custom variable.</br></br>
**NOTE:** The permissions specified in option 2 are irrelevant for customers who prefer to use their own network objects, such as VPC, NAT Gateway, Internet Gateway, etc.

### IAM Permissions for Azure
To be able to create Azure resources inside any Azure Account, you need to provide an Azure User or application registration service principal with the required permissions in order to run eDSF Kit Terraform.
**NOTE:** Assign the Owner role to the user or app registration service principal temporarily. More detailed permissions will be specified in the future.

## IAM Permissions for the DSF Instances on AWS

If you are running an installation example and want to provide your own instance profiles as variables, you can find samples of the
required permissions here - [DSF Instances Permissions](/dsf_instances_permissions_samples).

# Security Groups

If you are running an installation example and want to provide your own security groups as variables, you can find samples of the 
required security groups rules here - [Security Groups samples](/security_groups_samples).

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
2. Terraform leverages the cloud provider's shell environment for authentication. For AWS, refer to the [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html),
      and for Azure, refer to the [Azure CLI Configuration Guide](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli). In this example, we'll use environment variables for simplicity.
    - AWS environment variables
        ```bash
        export AWS_ACCESS_KEY_ID=${access_key}
        export AWS_SECRET_ACCESS_KEY=${secret_key}
        export AWS_REGION=${region}
    
        >>>> Fill the values of the access_key, secret_key and region placeholders, e.g., export AWS_ACCESS_KEY_ID=5J5AVVNNHYY4DM6ZJ5N46.
        ```
      
    - Azure environment variables

        ```bash
        export ARM_TENANT_ID=${tenant_id}
        export ARM_SUBSCRIPTION_ID=${subscription_id}
        export ARM_CLIENT_ID=${client_id}
        export ARM_CLIENT_SECRET=${client_secret}
    
        >>>> Fill the values of the tenant_id, subscription_id, client_id and client_secret placeholders, e.g., export ARM_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.
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

# Getting Ready to Upgrade

## Choosing the Upgrade Mode

eDSF Kit offers several upgrade modes:

* **CLI Upgrade Mode:** This mode offers a straightforward upgrade option that relies on running a Terraform script on the user's computer which must be a Linux/Unix machine, e.g, Mac.

  For more details, refer to [CLI Upgrade Mode](#cli-upgrade-mode).
* **Installer Machine Deployment Mode:** This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine that the user launches, instead of on their computer. This mode can be used if a Linux/Unix machine is not available, or eDSF Kit cannot be run on the available Linux/Unix machine, e.g., since it does not have permission or network access to the deployment environment, or if the user doesn't want to install additional software on their computer.

  For more details, refer to [Installer Machine Upgrade Mode](#installer-machine-upgrade-mode).

The first step in the upgrade is to choose the upgrade mode most appropriate to you.
If you need more information to decide on your preferred mode, refer to the detailed instructions for each mode [here](#upgrade).

## Upgrade Prerequisites

Before using eDSF Kit to upgrade DSF Hubs and Agentless Gateways, it is necessary to satisfy a set of prerequisites.

1. The upgrade requires access to the DSF installation software. [Click here to request access](https://docs.google.com/document/d/1Ci7sghwflPsfiEb7CH79z1bNI74x_lsChE5w_cG4rMs).
2. Only if you chose the [CLI Upgrade Mode](#cli-upgrade-mode), install [Git](https://git-scm.com).
3. Only if you chose the [CLI Upgrade Mode](#cli-upgrade-mode), install [Terraform](https://www.terraform.io). It is recommended on MacOS systems to use the "Package Manager" option during installation.
4. Only if you chose the [CLI Upgrade Mode](#cli-upgrade-mode), install [Python 3](https://www.python.org).
5. Latest Supported Terraform Version: 1.6.x. Using a higher version may result in unexpected behavior or errors.
6. The upgrade requires permission and network access (SSH) from your computer or the installer machine (depending on your choice of upgrade mode) to the deployed environment on AWS.

### Additional Prerequisites

If the DSF deployment has not been deployed using the eDSF Kit, it is also necessary to satisfy the following prerequisites:


1. Grant the DSF Hubs and Agentless Gateways IAM roles access to the S3 bucket containing the DSF installation software, use the permissions specified here - [IAM Permissions for Granting Access to DSF Installation](/permissions_samples/DSFIntallationAccessPermissions.txt).
2. Allow outbound connections from the DSF Hubs and Agentless Gateways to the S3 bucket containing the DSF installation software.
3. AWS CLI installed on the DSF Hubs and Agentless Gateways.

## Upgrade Software Location and Versioning

When using eDSF Kit, there is no need to manually download the DSF installation software, eDSF Kit will do that automatically based on the Sonar target version specified in the Terraform example.
In order to be able to download the upgrade software during upgrade, you must request access beforehand. See [Upgrade Prerequisites](#upgrade-prerequisites).

Sonar version constrains can be found in the <a href="https://github.com/imperva/dsfkit/blob/master/modules/aws/sonar-upgrader/README.md#sonar-version-constraints">Sonar Upgrader</a> module.

The target version should be specified in the Sonar upgrade example <a href="https://github.com/imperva/dsfkit/blob/master/examples/aws/sonar_upgrade/main.tf">main.tf</a> file, for example:

   ```terraform
   target_version = "4.12.0.10.0"
   ```

# Upgrade

After you have [chosen the upgrade mode](#choosing-the-upgrade-mode), follow the step-by-step instructions below to ensure a successful upgrade. If you have any questions or issues during the upgrade process, please contact [Imperva Technical Support](https://support.imperva.com/s/).

## CLI Upgrade Mode

This mode offers a straightforward deployment option that relies on running a Terraform script on the user's computer which must be a Linux/Unix machine, e.g, Mac.
This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments.

1. Download the zip file of the Sonar upgrade example: <a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/sonar_upgrade/sonar_upgrade_1_7_3.zip">sonar_upgrade_1_7_3.zip</a>.

2. Unzip the zip file in CLI or using your operating system's UI.
   For example, in CLI:
   ```bash
   unzip sonar_upgrade_<x_y_z>.zip
   
   >>>> Replace the x_y_z with the eDSF Kit version in the zip file name
   ```

3. In CLI, navigate to the directory which contains the Terraform files.
   ```bash
   cd sonar_upgrade_<x_y_z>
   
   >>>> Replace the x_y_z with the eDSF Kit version in the zip file name
   ```

4. Enter the details of DSF Hubs and Agentless Gateways which you want to upgrade, and the desired configuraiton options, in the <a href="https://github.com/imperva/dsfkit/blob/1.7.1/examples/aws/sonar_upgrade/main.tf">main.tf</a> file.


   More information can be found in the <a href="https://github.com/imperva/dsfkit/blob/master/modules/aws/sonar-upgrader/README.md#sonar-version-constraints">Sonar Upgrader</a> module.


   If you need help doing that, please contact [Imperva Technical Support](https://support.imperva.com/s/).

5. Run:
    ```bash
    terraform init
    ```

6. Run the upgrade:
    ```bash
    terraform apply
    ```

   Wait for it to complete.


7. To re-apply when there are no Terraform changes (the Terraform infrastructure matches the configuration), run:
   ```bash
   terraform apply -replace="module.sonar_upgrader.null_resource.upgrade_cmd"
   ```

**The CLI Upgrade is now completed and a functioning upgraded version of DSF is now available.**

## Installer Machine Upgrade Mode

This mode is similar to the CLI mode except that the Terraform is run on an EC2 machine that the user launches, instead of on their computer.
This mode can be used if a Linux/Unix machine is not available, or eDSF Kit cannot be run on the available Linux/Unix machine, e.g., since it does not have permission or network access to the deployment environment, or if the user doesn't want to install additional software on their computer.


1. In AWS, choose a region for the installer machine while keeping in mind that the machine should have access to the DSF environment that you want to upgrade, and preferably be in proximity to it.


2. **Launch an Instance:** Use the _RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2_ community AMI or similar.


3. Select t2.medium 'Instance type', or t3.medium if T2 is not available in the region.


4. Create or select an existing 'Key pair' that you will later use to run SSH to the installer machine. 


5. In the Network settings panel - make your configurations while keeping in mind that the installer machine should have access to the DSF environment that you want to deploy, and that your computer should have access to the installer machine.


6. In the “Advanced details” panel, copy and paste the contents of this [bash script](https://github.com/imperva/dsfkit/blob/1.7.3/installer_machine/upgrade_installer_machine_user_data.sh) into the [User data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html) textbox.


9. Click on **Launch Instance**. At this stage, the installer machine is initializing and downloading the necessary dependencies.


10. When launching is completed, run SSH to the installer machine from your computer:
     ```bash
     ssh -i ${key_pair_file} ec2-user@${installer_machine_public_ip}
   
    >>>> Replace the key_pair_file with the name of the file from step 4, and the installer_machine_public_ip with 
         the public IP of the installer machine which should now be available in the AWS EC2 console.
         E.g., ssh -i a_key_pair.pem ec2-user@1.2.3.4
     ```

    **NOTE:** You may need to decrease the access privileges of the key_pair_file in order to be able to use it in for ssh.
    For example: `chmode 400 a_key_pair.pem`

    
12. Continue by following the [CLI Upgrade Mode](#cli-upgrade-mode) beginning at step 1.

**Note:** It is safe to destroy the installer machine at any time, since currently no AWS resources are deployed during the upgrade process.

**The Installer Machine Deployment is now completed and a functioning upgraded version of DSF is now available.**

## Running the Python Upgrade Directly

If you do not wish to use Terraform to run the upgrade, it is possible to bypass it and run the Python utility directly.

Use the <a href="https://github.com/imperva/dsfkit/tree/1.7.3/modules/aws/sonar-upgrader/python_upgrader/README.md">Python Upgrader</a> utility.

# More Information

Information about additional topics can be found in specific examples, when relevant.

For example:  <a href="https://github.com/imperva/dsfkit/tree/1.7.3/examples/aws/installation/sonar_single_account_deployment/README.md">Sonar Single Account Deployment</a>

These topics include:
- Storing Terraform state in S3 bucket
- Working with DSF Hub and Agentless Gateway without outbound internet access

# Troubleshooting 

If you encounter a problem that is not covered below, please open a [Github issue](https://github.com/imperva/dsfkit/issues/new) and attach the relevant terraform logs.
You can automatically persist the logs with the following apply command:
```
terraform apply -auto-approve | tee tf.log
```

Below is a list of possible issues and troubleshooting remediations. 

<details>
 <summary>Common issues</summary>
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
   <td>Sonar HADR setup internal error
   </td>
   <td>Replication failed! <br>
       Replication script exited with code 1
   </td>
   <td>Contact Imperva's Technical Support.
   </td>
  </tr>
  <tr>
   <td>Sonar federation internal error
   </td>
   <td>python_commons.http_client.UnexpectedStatusCode: Failed to run: federated_asset_connection_sync. Check /data_vol/sonar-dsf/jsonar/logs/sonarfinder/catalina.out for details., <br>
       status: 500, data: None <br>
       See log "/data_vol/sonar-dsf/jsonar/logs/sonarg/federated.log" for details
   </td>
   <td>Contact Imperva's Technical Support. 
   </td>
  </tr>
  <tr>
   <td>DAM configuration script exists with status code 28
   </td>
   <td>: exit status 28. Output: + set -e
   </td>
   <td>Rerun “terraform apply”. 
   </td>
  </tr>
 </table>
</details>
<details>
 <summary>AWS issues</summary>
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
   <td>VPC quota exceeded
   </td>
   <td>error creating EC2 VPC: VpcLimitExceeded: The maximum number of VPCs has been reached
   </td>
   <td>Remove unneeded vpc via <a href="https://console.aws.amazon.com/vpc/home#vpcs:">vpc dashboard</a>, or increase vpc quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/vpc/quotas/L-F678F1CE">this page</a> and run again.
   </td>
  </tr>
  <tr>
   <td>Elastic IP quota exceeded
   </td>
   <td>Error creating EIP: AddressLimitExceeded: The maximum number of addresses has been reached
   </td>
   <td>Remove unneeded Elastic IPs via <a href="https://console.aws.amazon.com/ec2/home#Addresses:">this dashboard</a>, or increase Elastic IP quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/ec2/quotas/L-0263D0A3">this page</a> and run again.
   </td>
  </tr>
  <tr>
   <td>Option Group quota exceeded
   </td>
   <td>Error: "Cannot create more than 20 option groups". Remediation similar to the other exceeded errors
   </td>
   <td>Remove unneeded Option Groups <a href="https://console.aws.amazon.com/rds/home#option-groups-list:">here</a>, or increase Option Group quota via <a href="https://console.aws.amazon.com/servicequotas/home/services/rds/quotas/L-9FA33840">this page</a> and run again.
   </td>
  </tr>
  <tr>
   <td>AWS glitch
   </td>
   <td>Error: creating EC2 Instance: InvalidNetworkInterfaceID.NotFound: The networkInterface ID 'eni-xxx does not exist
   </td>
   <td>Rerun “terraform apply”.
   </td>
  </tr>
  <tr>
   <td>AWS ENI deletion limitation
   </td>
   <td>error deleting security group: DependencyViolation: resource sg-xxxxxxxxxxxxx has a dependent object  
   </td>
   <td>According to AWS support, an ENI can take up to 24 hours to be deleted. Suggestion: Try to delete the ENI from AWS console or wait for 24 hours.
   </td>
  </tr>
  <tr>
   <td>Blocked by Security Group or Network
   </td>
   <td>timeout - last error: dial tcp x.y.z.w:22: i/o timeout <br>
       or <br>
       timeout - last error: Error connecting to bastion: dial tcp x.y.z.w:22: connect: connection timed out
   </td>
   <td>Check your security group and network configuration
   </td>
  </tr>
  <tr>
   <td>Invalid EC2 SSH Keys
   </td>
   <td>timeout - last error: Error connecting to bastion: ssh: handshake failed: <br>
       ssh: unable to authenticate, attempted methods [none publickey],  no supported methods remain
   </td>
   <td>Check the SSH keys you are using and the SSH keys variables values that you are passing.
   </td>
  </tr>
  <tr>
   <td>No outbound internet access
   </td>
   <td>Error: No outbound internet access. Either enable outbound internet access, or make sure x is installed in the base ami
   </td>
   <td>If you intended the DSF node to have outbound intent access, then make sure the private subnets have routing to a NAT gateway or equivalent. If you didn't intend the DSF node to have outbound internet access, follow the instructions for 'Deploying DSF Nodes without Outbound Internet Access' in your example.  
   </td>
  </tr>
  <tr>
   <td>Sonar upgrade tarball download error - missing IAM role on Sonar node EC2
   </td>
   <td>Downloading tarball...<br>
       fatal error: Unable to locate credentials
   </td>
   <td>Attach an IAM role to the Sonar node EC2 with permission to download the tarball. Follow the instructions in the <a href="https://github.com/imperva/dsfkit/tree/master#additional-prerequisites">Additional Prerequisites</a>. 
   </td>
  </tr>
  <tr>
   <td>Sonar upgrade tarball download error - missing IAM role permission on Sonar node EC2
   </td>
   <td>Downloading tarball...<br>
       fatal error: An error occurred (403) when calling the HeadObject operation: Forbidden
   </td>
   <td>Add a policy to the IAM role attached to the Sonar node EC2 with permission to download the tarball. Follow the instructions in the <a href="https://github.com/imperva/dsfkit/tree/master#additional-prerequisites">Additional Prerequisites</a>.
   </td>
  </tr>
  <tr>
   <td>Sonar upgrade tarball download error - aws cli profile misconfiguration in Sonar node EC2
   </td>
   <td>Downloading tarball...<br>
       fatal error: An error occurred (403) when calling the HeadObject operation: Forbidden
   </td>
   <td>Connect with SSH to the Sonar node EC2 and fix the aws cli profile misconfiguration. Run, for example, 'aws sts get-caller-identity' to test it.  
   </td>
  </tr>
 </table></details>
<details>
 <summary>Azure issues</summary>
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
   <td>Cores quota exceeded
   </td>
   <td>Error: creating Linux Virtual Machine ...: compute.VirtualMachinesClient#CreateOrUpdate: Failure sending request: StatusCode=0 -- Original Error: autorest/azure: Service returned an error. Status=<nil> Code="OperationNotAllowed" Message="Operation could not be completed as it results in exceeding approved *** Cores quota.
   </td>
   <td>
   Increase the quota using the link provided in your own error message.
   </td>
  </tr>
  <tr>
   <td>Public IP quota exceeded
   </td>
   <td>Error: "Cannot create more than 10 public IP addresses for this subscription in this region."
   </td>
   <td>
   Increase the quota using the link provided in your own error message.
   </td>
  </tr>
 </table>
</details>


