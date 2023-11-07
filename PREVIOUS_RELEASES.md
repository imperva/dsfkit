The following table lists _previous_ releases of eDSF Kit versions, their release date, a high-level summary of each version's content and whether they are active or deprecated.

<table>
  <tr>
   <td><strong>Date</strong>
   </td>
   <td><strong>Version</strong>
   </td>
   <td><strong>Details</strong>
   </td>
   <td><strong>Status</strong>
   </td>
  </tr>
  <tr>
   <td>3 Nov 2022
   </td>
   <td>1.0.0
   </td>
   <td>First release for SEs. Beta.
   </td>
   <td>Deprecated
   </td>
  </tr>
  <tr>
   <td>20 Nov 2022
   </td>
   <td>1.1.0
   </td>
   <td>Second Release for SEs. Beta.
   </td>
   <td>Deprecated
   </td>
  </tr>
  <tr>
   <td>3 Jan 2023
   </td>
   <td>1.2.0
   </td>
   <td>1. Added multi accounts example. <br>2. Changed modules interface.
   </td>
   <td>Deprecated
   </td>
  </tr>
  <tr>
   <td>19 Jan 2023
   </td>
   <td>1.3.4
   </td>
   <td>1. Refactored directory structure. <br>2. Released to terraform registry. <br>3. Supported DSF Hub / Agentless Gateway on RedHat 7 ami. <br>4. Restricted permissions for Sonar installation. <br>5. Added the module's version to the examples.
   </td>
   <td>Deprecated
   </td>
  </tr>
  <tr>
   <td>26 Jan 2023
   </td>
   <td>1.3.5
   </td>
   <td>1. Enabled creating RDS MsSQL with synthetic data for POC purposes. <br>2. Fixed manual and automatic installer machine deployments. 
   </td>
   <td>Deprecated
   </td>
  </tr>
  <tr>
   <td>5 Feb 2023
   </td>
   <td>1.3.6
   </td>
   <td>Supported SSH proxy for DSF Hub / Agentless Gateway in modules: hub, agentless-gw, federation, poc-db-onboarder.
   </td>
   <td>Deprecated
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
      <br>5. Added the option to provide EC2 AMI filter details for the DSF Hub and Agentless Gateway via the 'ami' variable. 
      <br>6. For user-provided AMI for the DSF node (DSF Hub and the Agentless Gateway) that denies execute access in '/tmp' folder, added the option to specify an alternative path via the 'terraform_script_path_folder' variable.
      <br>7. Passed the password of the DSF node via AWS Secrets Manager.
      <br>8. Added the option to provide a custom S3 bucket location for the Sonar binaries via the 'tarball_location' variable.
      <br>9. Bug fixes.
   </td>
   <td>Active
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
   <td>Active
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
   <td>Active
   </td>
  </tr>

</table>
