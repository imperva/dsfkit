[Temporarly, the full documentation can be found here](https://docs.google.com/document/d/1wzCrAkU2tk5e7L8pYLOeyJYai7upFBLhANWY1yDTOao/edit?usp=sharing)

<!-- Output copied to clipboard! -->

<!-----

You have some errors, warnings, or alerts. If you are using reckless mode, turn it off to see inline alerts.
* ERRORs: 3
* WARNINGs: 0
* ALERTS: 29

Conversion time: 8.599 seconds.


Using this Markdown file:

1. Paste this output into your source file.
2. See the notes and action items below regarding this conversion run.
3. Check the rendered output (headings, lists, code blocks, tables) for proper
   formatting and use a linkchecker before you publish this page.

Conversion notes:

* Docs to Markdown version 1.0β33
* Tue Nov 22 2022 01:19:03 GMT-0800 (PST)
* Source doc: Untitled document
* Tables are currently converted to HTML tables.

ERROR:
undefined internal link to this URL: "#heading=h.c1f4m4vol1z".link text: IAM Role section
?Did you generate a TOC?


ERROR:
undefined internal link to this URL: "#heading=h.nr37ktb7vrv4".link text: Customizing Demos - Examples/Recipes
?Did you generate a TOC?


ERROR:
undefined internal link to this URL: "#heading=h.nr37ktb7vrv4".link text: Customizing Demos
?Did you generate a TOC?

* This document has images: check for >>>>>  gd2md-html alert:  inline image link in generated source and store images to your server. NOTE: Images in exported zip file from Google Docs may not appear in  the same order as they do in your doc. Please check the images!


WARNING:
You have 8 H1 headings. You may want to use the "H1 -> H2" option to demote all headings by one level.

----->


<p style="color: red; font-weight: bold">>>>>>  gd2md-html alert:  ERRORs: 3; WARNINGs: 1; ALERTS: 29.</p>
<ul style="color: red; font-weight: bold"><li>See top comment block for details on ERRORs and WARNINGs. <li>In the converted Markdown or HTML, search for inline alerts that start with >>>>>  gd2md-html alert:  for specific instances that need correction.</ul>

<p style="color: red; font-weight: bold">Links to alert messages:</p><a href="#gdcalert1">alert1</a>
<a href="#gdcalert2">alert2</a>
<a href="#gdcalert3">alert3</a>
<a href="#gdcalert4">alert4</a>
<a href="#gdcalert5">alert5</a>
<a href="#gdcalert6">alert6</a>
<a href="#gdcalert7">alert7</a>
<a href="#gdcalert8">alert8</a>
<a href="#gdcalert9">alert9</a>
<a href="#gdcalert10">alert10</a>
<a href="#gdcalert11">alert11</a>
<a href="#gdcalert12">alert12</a>
<a href="#gdcalert13">alert13</a>
<a href="#gdcalert14">alert14</a>
<a href="#gdcalert15">alert15</a>
<a href="#gdcalert16">alert16</a>
<a href="#gdcalert17">alert17</a>
<a href="#gdcalert18">alert18</a>
<a href="#gdcalert19">alert19</a>
<a href="#gdcalert20">alert20</a>
<a href="#gdcalert21">alert21</a>
<a href="#gdcalert22">alert22</a>
<a href="#gdcalert23">alert23</a>
<a href="#gdcalert24">alert24</a>
<a href="#gdcalert25">alert25</a>
<a href="#gdcalert26">alert26</a>
<a href="#gdcalert27">alert27</a>
<a href="#gdcalert28">alert28</a>
<a href="#gdcalert29">alert29</a>

<p style="color: red; font-weight: bold">>>>>> PLEASE check and correct alert issues and delete this message and the inline alerts.<hr></p>



# Data Security Fabric (DSF) Kit Installation Guide


[TOC]



# About This Guide

This guide is intended for Imperva Sales Engineers (SE) for the purpose of Proof-of-Concept (POC) demonstrations that deploy the Imperva Data Security Fabric (DSF) Kit solution.


```
NOTE: This guide is for INTERNAL USE ONLY, to be used by in-house staff for POCs and demos of the new DSF installation.  The current focus is on Sonar parts only.
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
   <td><code># Code will be called out using this font and includes [ brackets ] for easy identification of required user input. #</code>
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

**Quick Links **

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
   <td><strong>Doc  \
Version</strong>
   </td>
   <td><strong>DSF Version</strong>
   </td>
   <td><strong>Summarized Description of Updates</strong>
   </td>
  </tr>
  <tr>
   <td>Nov 2022
   </td>
   <td>1-220311
   </td>
   <td>1.0.0
   </td>
   <td>Initial creation and publication of DSF Installation guide.
   </td>
  </tr>
</table>



# Getting Ready to Deploy  

The Imperva DSFKit enables you to easily install a working instance of the DSF Portal, providing access to the full suite of DSF products including Sonar, DAM, and DRA. The DSFKit can be easily installed by following the steps in this guide and is currently available for POC scenarios on AWS only. 

Before installing DSFKit, it is necessary to complete the following steps:



1. Create an AWS User with secret and access keys which comply with the required IAM permissions (see 

<p id="gdcalert1" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: undefined internal link (link text: "IAM Role section"). Did you generate a TOC? </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert2">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>

[IAM Role section](#heading=h.c1f4m4vol1z)).
2. Deployment requires access to the tarball containing Sonar binaries. The tarball is located in a dedicated AWS Bucket owned by Imperva. Click [here](https://docs.google.com/forms/d/e/1FAIpQLSdnVaw48FlElP9Po_36LLsZELsanzpVnt8J08nymBqHuX_ddA/viewform) to request access to download this file.  
3. UI Installation Mode requires access to a Terraform Cloud Platform account. Any  account may be used, whether the account is owned by Imperva or the customer. Click [here](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform) to request access to Imperva's Terraform Account.
4. [Download Git](https://git-scm.com/downloads).
5. [Download Terraform](https://www.terraform.io/downloads). It is recommended on MacOS systems to use the "PACKAGE MANAGER" option during installation.

    ```
NOTE: Note: It may take several hours for access to be granted to AWS and Terraform in Steps 2 and 3.
```




## Binaries Location and Versioning

When using DSFKit there is no need to manually download the DSF binaries, DSFKit will do that automatically based on the Sonar version specified in the Terraform recipe.

**File**: deploy/examples/se_demo/variables.tf` `


```
 variable "sonar_version" {
  type    = string
  default = "4.10"
}


```
NOTE: DSFKit version 1.0.0 is available and supports Sonar version 4.10.
```



# DSFKit Installation 

DSFKit is the official Terraform toolkit designed to automate the deployment and maintenance of Imperva's Data Security Fabric (DSF). DSFKit offers two installation methods:



* **UI Installation Mode:** This method makes use of Terraform Cloud, a service that exposes a dedicated UI to create and destroy resources via Terraform.** **This method is used in cases where we don't want to install any software on the client's machine. This can be used to demo DSF on an Imperva AWS Account or on a customer’s AWS account (if the customer supplies credentials).  \

* **CLI Installation Mode: **This method offers a straightforward installation option that relies on entering and running a Terraform script. This method is recommended when the customer wants to install the demo environment on their own machine, or when using the Terraform Cloud is not possible.

Please select the most appropriate method and follow the step-by-step instructions to ensure a successful installation. If you have any questions or issues during the installation process, please contact [Imperva Technical Support](https://support.imperva.com/s/). 


## UI Installation Mode

The User Interface (UI) installation mode uses the Terraform Cloud (TF Cloud) service, which allows installing and managing deployments via a dedicated UI. Deploying the environment is easily triggered by clicking a button within the Terraform interface, which then pulls the required code from the Imperva GitHub repository and automatically runs the scripts remotely. 

[Open Terraform Cloud Account - Request Form](https://docs.google.com/forms/d/e/1FAIpQLSfgJh4kXYRD08xDsFyYgaYsS3ebhVrBTWvntcMCutSf0kNV2w/viewform)


```
NOTE: The UI Installation Mode can be used to demo DSF in a customer's Terraform account or the Imperva Terraform account, which is accessible for internal use (SEs, QA, Research, etc') and can be used to deploy/destroy demo environments on AWS accounts owned by Imperva.
```


Please complete the following step-by-step installation instructions provided below and contact [Imperva Technical Support](https://support.imperva.com/s/) with any issues or questions.


### **UI Installation Steps**

Follow these instructions to install DSFKit via the UI Installation Mode:



1. **Connect to Terraform Cloud: **Connect to the desired Terraform cloud account, either the internal Imperva account or a customer account if one is available.
2. **Create a New Workspace**: Complete these steps to create a new workspace in Terraform cloud that will be used for the DSFKit deployment. 
* Click the **+ New Workspace** button in the top navigation bar to open the Create a new Workspace page. \


<p id="gdcalert2" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image1.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert3">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image1.png "image_tooltip")

* Choose **Version Control Workflow** from the workflow type options. \


<p id="gdcalert3" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image2.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert4">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image2.png "image_tooltip")

* Choose **github.com/dsfkit** as the version control provider.  \


<p id="gdcalert4" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image3.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert5">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image3.png "image_tooltip")

* Choose **imperva/dsfkit **as the repository.  \
If this option is not displayed, type imperva/dsfkit in the “Filter” textbox. \


<p id="gdcalert5" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image4.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert6">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image4.png "image_tooltip")

* Name the workspace in the following format:  \
Example:  `dsfkit-[NAME_OF_CUSTOMER]-[NAME_OF_ENVIRONMENT] \
`
* Click on the Advanced options button. \


<p id="gdcalert6" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image5.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert7">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image5.png "image_tooltip")

* Enter “deploy/examples/se_demo” into the Terraform working directory input field. To understand what the se_demo example consists of or the create a custom demo, please see more details in the 

<p id="gdcalert7" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: undefined internal link (link text: "Customizing Demos - Examples/Recipes"). Did you generate a TOC? </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert8">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>

[Customizing Demos - Examples/Recipes](#heading=h.nr37ktb7vrv4) section. \


<p id="gdcalert8" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image6.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert9">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image6.png "image_tooltip")
    
* Select the “Auto apply” option as the Apply Method. \


<p id="gdcalert9" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image7.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert10">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image7.png "image_tooltip")

* To avoid automatic Terraform configuration changes when the GitHub repo updates, set the following values under “Run triggers”: \


<p id="gdcalert10" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image8.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert11">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image8.png "image_tooltip")
 \
As displayed in the above screenshot, the Custom Regular Expression field value should be “23b82265”.
* Click “Create workspace” to finish and save the new DSFKit workspace. \


<p id="gdcalert11" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image9.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert12">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image9.png "image_tooltip")


     \


3. **Add the AWS Variables: **The next few steps will configure the required AWS variables.
* Once Terraform has finished creating the DSFKit workspace, click the Workspace Overview button to continue. \


<p id="gdcalert12" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image10.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert13">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image10.png "image_tooltip")

* Click on the Configure Variables button. \


<p id="gdcalert13" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image11.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert14">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image11.png "image_tooltip")

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




<p id="gdcalert14" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image12.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert15">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image12.png "image_tooltip")
  \




4. **Run the Imperva GitHub Code: **The following steps complete setting up the DSFKit workspace and run the Imperva GitHub code. 
* Click on the **Actions** dropdown button from the top navigation bar, and select the Start **New Run** option from the list.  \


<p id="gdcalert15" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image13.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert16">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image13.png "image_tooltip")

* Enter a unique alphanumeric name for the run, and click on the **Start Run** button. As the run completes, Terraform will show what resources it has created and what resources are currently provisioned. \


<p id="gdcalert16" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image14.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert17">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image14.png "image_tooltip")

5. **Complete the Workspace Deployment: **These steps provide the necessary information to view and access the newly created workspace, and a fully functioning instance of Imperva’s DSF. 
* Once the run has completed, click to expand the **Apply Finished** section. 

<p id="gdcalert17" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image15.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert18">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image15.png "image_tooltip")
 \

* Scroll to the bottom and expand the **Outputs** section to find the State Versions Created link and the auto-generated password under “admin-password” which will be  used to log into the DSF Portal in a future step. \


<p id="gdcalert18" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image16.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert19">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image16.png "image_tooltip")
 \


<p id="gdcalert19" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image17.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert20">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image17.png "image_tooltip")
 \

* Expand outputs to view the environment settings and locate the **dsf_hub_web_console_url**.  \


<p id="gdcalert20" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image18.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert21">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image18.png "image_tooltip")
 \

* Copy the **dsf_hub_web_console_url** into a web browser to open the Imperva Data Security Fabric (DSF) login screen. \


<p id="gdcalert21" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image19.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert22">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image19.png "image_tooltip")
 \


        ```
NOTE: Sonar is installed with a self-signed certificate, as result when opening the web page you may see a warning notification. Please click "Proceed to domain.com (unsafe)".
```



        

<p id="gdcalert22" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image20.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert23">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image20.png "image_tooltip")
 \


* Enter “admin” into the username field and the auto-generated password from the previous step to find the unmasked “admin_password” output. Click **Sign In**.

**The UI Installation is now complete and a functioning version of DSF is now available.**


## Local CLI Installation Mode

This mode makes use of the Terraform Command Line Interface (CLI) to deploy and manage environments. Terraform CLI uses a bash script and therefore requires a Linux/Mac machine. To deploy DSFKit using the CLI installation mode, please complete the following steps:



1. [Download Git ](https://git-scm.com/downloads)
2. [Download Terraform ](https://www.terraform.io/downloads)
3. In case the “example” includes the creation of a “demo db” via the Onboarder then [Download Java 11](https://www.oracle.com/il-en/java/technologies/javase/jdk11-archive-downloads.html) and make sure it is your default java version:

        ```
        > java -version 

The output should be something similar to the following:
> java version "11.x.x" 2021-04-20 LTS

        ```



### **Local CLI Installation Steps**

Follow these instructions to install DSFKit via the local CLI mode.


```
NOTE: Update the values for the required parameters to complete the installation: example_name, aws_access_key_id, aws_secret_access_key and region
```




1. Git clone dfskit:  \
<code>> git clone [https://github.com/imperva/dsfkit.git](https://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@github.com/imperva/dsfkit.git)</code>
2. Navigate to the directory "examples":  \
<code>> cd dsfkit/deploy/examples/${example_name}</code>

    DSFKit arrives with a built-in example “se_demo” which should meet most POC requirements. See “

<p id="gdcalert23" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: undefined internal link (link text: "Customizing Demos"). Did you generate a TOC? </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert24">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>

[Customizing Demos](#heading=h.nr37ktb7vrv4)” to understand the environment created with the “se_demo” example and to learn how to create specific requirements if needed.  \
For simplicity we will use the following: \
<code>> cd dsfkit/deploy/examples/se_demo</code>

3. Terraform uses the AWS shell environment for AWS authentication. More details on how to authenticate with AWS are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).  \
For simplicity, in this example we will use environment variables:

    ```
    export AWS_ACCESS_KEY_ID=${access_key}
    export AWS_SECRET_ACCESS_KEY=${secret_key}
    export AWS_REGION=${region}
    ```


4. Run:` >  terraform init `
5. Run: `>  terraform apply -auto-approve`

    This should take about 30 minutes.

6. Extract the web console admin password and DSF URL using: \
`> terraform output "admin_password" && terraform output "dsf_hub_web_console_url"`
7. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step. 

**The CLI Installation is now complete and a functioning version of DSF is now available.**


## Installer Machine Mode

If a Linux machine is not available or DSFKit cannot be run locally, Imperva supports deployments via a DSFKit Installer Machine on AWS. This dedicated machine acts as a “bastion server”, and the user only needs to create a t2.medium EC2 machine and OS: RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2:

This can be done either manually or via an automated process. Select a method below and follow the instructions:


## Manual Installer Machine

Complete these steps to manually create an installer machine:



1. **Launch an Instance: **Search  for RHEL-8.6.0_HVM-20220503-x86_64-2-Hourly2-GP2 Image and click “enter”

    

<p id="gdcalert24" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image21.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert25">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image21.png "image_tooltip")


2. Choose the “Community AMI”.

    

<p id="gdcalert25" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image22.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert26">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image22.png "image_tooltip")
 \


3. Expand the “Advanced details” panel. \


<p id="gdcalert26" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image23.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert27">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image23.png "image_tooltip")
 \

4. Scroll down to find the “User data” input and paste [this bash script](https://github.com/imperva/dsfkit/blob/master/deploy/installer_machine/prepare_installer.tpl) into the “User data” textbox. \


<p id="gdcalert27" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image24.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert28">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image24.png "image_tooltip")

5. Update the following parameter values in the bash script: 
    1. example_name (i.e se_demo)
    2. aws_access_key_id
    3. aws_secret_access_key
    4. region
    5. web_console_cidr
6. Click on **Launch Instance**. At this stage the Installer Machine is initializing and will automatically create all of the other necessary resources (Hub, GWs etc). View the progress logs by SSH into the machine and view the “user-data” logs”` > tail -f /var/logs/user-data.log`

    ```
NOTES: 
In this example 'web_console_cidr' was set to 0.0.0.0/0. This configuration opens the Hub web console as a public web site. If needed, specify a more restricted IP and CIDR range.
The link to the GitHub repo can be updated and supplied by you, in the case of custom demos and examples. See Customizing Demos for more information.
DO NOT DESTROY THE INSTALLER MACHINE UNTIL YOU ARE DONE AND HAVE DESTROYED ALL OTHER RESOURCES. OTHERWISE THERE WILL BE UNDELETABLE RESOURCES. For more information see  Uninstalling Installer Machine Mode section.
```


7. When installation is done extract the web console password and DSF URL using:
    6. `> cd /dsfkit/deploy/examples/&lt;example-name>`
    7. `> terraform output "admin_password" && terraform output "dsf_hub_web_console_url"`
8. Access the DSF Portal by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password generated in the previous step.  \



### Automated Installer Machine

In case you don’t want to manually create the Installer Machine, you can automate the creation of the Installer Machine. DSFKit exposes a dedicated Terraform example that automatically creates the installer machine with the “user-data”.  Complete these steps to automate the creation of an installer machine:

 \
To use the Terraform installer example follow the following step:



1. <code>> git clone [https://github.com/imperva/dsfkit.git](https://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@github.com/imperva/dsfkit.git)</code>
2. <code>> cd dsfkit/deploy/installer_machine </code>
3. <code>> terraform init</code>
4. <code>> terraform apply -auto-approve</code>
5. This script will prompt you to input the aws_access_key, aws_secret_key and aws_region parameters. \


    ```
NOTE: At this stage the Installer Machine is initializing. At its initialization it will automatically create all the other resources (Hub, GWs etc).

** DO NOT DESTROY THE INSTALLER MACHINE UNTIL YOU ARE DONE AND DESTROYED ALL THE OTHER RESOURCES. OTHERWISE YOU WILL LEAVE UNDELETABLE RESOURCES ** for more information see  Uninstalling Installer Machine Mode section
```


6. After the the first phase of the installation is completed, it outputs the following ssh commands, for example:

    ```
    installer_machine_ssh_command = "ssh -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17"
    logs_tail_ssh_command = "ssh -o StrictHostKeyChecking='no' -i ssh_keys/installer_ssh_key ec2-user@3.70.181.17 -C 'sudo tail -f /var/log/user-data.log'"
    ```


7. The second and last phase of the installation runs in the background. To follow it and know when it is completed, run the `logs_tail_ssh_command` which appears in the first phase output.
8. After the installation is completed, run ssh to the installer machine using the `installer_machine_ssh_command` which appears in the first phase output.
9. `> cd /dsfkit/deploy/examples/&lt;example-name>`
10. Extract the web console admin password and DSF URL using: \
`> terraform output "admin_password" && terraform output "dsf_hub_web_console_url"`
11. Access the DSF Hub by entering the DSF URL into a web browser. Enter “admin” as the username and the admin_password as the password outputted in the previous step. 

    ```
NOTE: The Terraform script is OS-Safe, as it doesn't run any bash script.
```




# Customizing Demos - Examples/Recipes 

DSFKit ships 2 built-in examples/recipes which are already configured to deploy a basic Sonar environment:



1. “se_demo” recipe, consist of:
    1. New VPC
    2. 1 Hub
    3. 2 GW
    4. Federation
    5. Creation of a new “Demo DB”
    6. Auto configuration of new “Demo DB” to enable native audit
    7. Onboarding database into Sonar \

2. “se_demo_hadr” recipe, consist of:
    8. New VPC
    9. 1 Primary Hub
    10. 1 Secondary Hub
    11. 2 GW
    12. Federation
    13. HADR

It is also possible to accommodate varying system requirements and deployments.  To customize the demo, please complete the following steps: \




1. **<span style="text-decoration:underline;">Fork</span>** dsfkit from git. \

2. In the Git account assemble a new Terraform recipe that meets the necessary requirements. 

    ```
    > cd deploy/examples/<YOUR CUSTOM EXAMPLE>
    > terraform init
    > terraform appy -auto-approve

    ```



# IAM Roles

To be able to create AWS resources inside any AWS Account you need to provide an AWS User with the required permissions needed in order to run DSFKit Terraform.


```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "secretsmanager:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "sts:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ec2:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "rds:*",
            "Resource": "*"
        },

        {
            "Effect": "Allow",
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}


```
NOTE: Currently the IAM Role is too broad and we are working on restricting it to the minimum.
```



# DSFKit Uninstallation

Please select the most appropriate method to uninstall and destroy the workspace.


## UI Mode

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.



1. To destroy the environment, click on Settings and find Destruction and Deletion from the navigation menu to open the Destroy Infrastructure page. Ensure that the Allow Destroy Plans toggle is selected, and click on the Queue Destroy Plan button to begin.  \


<p id="gdcalert28" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image25.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert29">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image25.png "image_tooltip")

2. The installed environment is now destroyed and the workspace may be re-used if needed. If this workspace is not being re-used, it may be removed with “Force delete from Terraform Cloud” that can be found under Settings. \


<p id="gdcalert29" ><span style="color: red; font-weight: bold">>>>>>  gd2md-html alert: inline image link here (to images/image26.png). Store image on your image server and adjust path/filename/extension if necessary. </span><br>(<a href="#">Back to top</a>)(<a href="#gdcalert30">Next alert</a>)<br><span style="color: red; font-weight: bold">>>>>> </span></p>


![alt_text](images/image26.png "image_tooltip")


    ```
NOTE: Do not remove the workspace before the deployment is completely destroyed. Doing so may lead to leftovers in your AWS account that will require manual deletion which is a tedious process.
```




## Local CLI Mode 

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.



1. cd into the installed “example”:  \
`cd deploy/examples/se_demo`
2. Run: 

    ```
    > terraform destroy -auto-approve

    ```



## Installer Machine Mode 

Please complete the following steps to completely uninstall the Imperva DSFKit and remove it from the application and system.



1. ssh into the “Installer Machine”.
2. cd into the installed “example”: `cd /dsfkit/deploy/examples/&lt;example-name>`
3. Run:`  `

    ```
    sudo su
export AWS_ACCESS_KEY_ID=${access_key}
export AWS_SECRET_ACCESS_KEY=${secret_key}
export AWS_REGION=${region}
    terraform destroy -auto-approve
    ```


4. Wait for the environment to be destroyed.

#### 
    Manual Installer Machine

1. Exit from the “Installer Machine”.
2. On the local machine, cd into deploy/installer_machine/.
3. `> terraform destroy` `-auto-approve`

#### 
    Automated Installer Machine

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



# Property Rights Notice

© 2002 - 2022 Imperva, Inc. All Rights Reserved. 

THIS DOCUMENT IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. IN NO EVENT SHALL IMPERVA BE LIABLE FOR ANY CLAIM OR DAMAGES OR OTHER LIABILITY, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES OF ANY KIND ARISING FROM ANY ERROR IN THIS DOCUMENT, INCLUDING WITHOUT LIMITATION ANY LOSS OR INTERRUPTION OF BUSINESS, PROFITS, USE OR DATA.

No part of this document may be used, disclosed, modified, reproduced, displayed, performed, distributed, stored in a retrieval system, or translated into any language in any form or by any means without the written permission of Imperva, Inc. To obtain this permission, write to the attention of the Imperva Legal Department at: 1 Curiosity Way, Suite 103, San Mateo, CA 94403.

Information in this document is subject to change without notice and does not represent a commitment on the part of Imperva, Inc. Imperva reserves the right to modify or remove any of the features or components described in this document for the final product or a future version of the product, without notice. The software described in this document is furnished under a license agreement. The software may be used only in accordance with the terms of this agreement.

This document contains proprietary and confidential information of Imperva, Inc. Imperva and its licensors retain all ownership and intellectual property rights to this document. This document is solely for the use of authorized Imperva customers.

**TRADEMARK ATTRIBUTIONS**

Imperva, the Imperva logo, SecureSphere, Incapsula, CounterBreach, ThreatRadar, Camouflage, Attack Analytics, Prevoty and design are trademarks of Imperva, Inc. and its subsidiaries. 

All other brand and product names are trademarks or registered trademarks of their respective owners.

**PATENT INFORMATION**

The software described by this document may be covered by one or more of the following patents:

US Patent Nos. 7,640,235, 7,743,420, 7,752,662, 8,024,804, 8,051,484, 8,056,141, 8,135,948, 8,181,246, 8,392,963, 8,448,233, 8,453,255, 8,713,682, 8,752,208, 8,869,279 and 8,904,558, 8,973,142, 8,984,630, 8,997,232, 9,009,832, 9,027,136, 9,027,137, 9,128,941, 9,148,440, 9,148,446 and 9,401,927.

Imperva Inc.

1 Curiosity Way, Suite 103

San Mateo, CA 94403 \
United States \
Tel:  +1 (650) 345-9000 \
Fax: +1 (650) 345-9004
