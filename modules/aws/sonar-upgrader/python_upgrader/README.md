# Python Upgrader
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This utility is designed for upgrading DSF Hubs and Agentless Gateways (formerly Sonar).

If you do not wish to use Terraform to run the upgrade, it is possible to bypass it and run the Python utility directly. 

## Prerequisites

Before using eDSF Kit to upgrade DSF Hubs and Agentless Gateways, it is necessary to satisfy a set of prerequisites.

1. The upgrade requires access to the DSF installation software. [Click here to request access](https://github.com/imperva/dsfkit/blob/1.7.19/REQUEST_ACCESS_AWS.md).
2. Install [Python 3](https://www.python.org).
3. The upgrade requires permission and network access (SSH) from your computer or the installer machine (depending on your choice of upgrade mode) to the deployed environment on AWS.

If the DSF deployment has not been deployed using the eDSF Kit, it is also necessary to satisfy the following prerequisites:


1. Grant the DSF Hubs and Agentless Gateways IAM roles access to the S3 bucket containing the DSF installation software, use the permissions specified here - [IAM Permissions for Granting Access to DSF Installation](https://github.com/imperva/dsfkit/blob/master/permissions_samples/aws/DSFIntallationAccessPermissions.txt).
2. Allow outbound connections from the DSF Hubs and Agentless Gateways to the S3 bucket containing the DSF installation software.
3. AWS CLI installed on the DSF Hubs and Agentless Gateways.

## Usage

Run the following command and replace [arguments] with the specific arguments required 
for your environment configuration:

`python3 -u -m upgrade.main [arguments]`

For a list of available arguments and their descriptions, use the following command:

`python3 -u -m upgrade.main -h`

### Usage Examples

In order to run the python command mentioned above, there is a need to provide JSON strings representing the DSF Hubs 
and/or Agentless Gateways that you want to upgrade.

Building large JSON structures and providing them as arguments in command line is an error-prone process. Follow these 
instructions to accomplish this task:

1. Create the DSF Hub and Agentless Gateways JSON structures in a readable format which includes new lines and indentations.
   For example, for the Agentless Gateways:

   ```
   [
       {
           "main": {
               "host": "10.0.1.1", 
               "ssh_user": "ec2-user", 
               "ssh_private_key_file_path": "/home/ssh_key2.pem"
           }, 
           "dr": {
               "host": "10.2.1.1", 
               "ssh_user": "ec2-user", 
               "ssh_private_key_file_path": "/home/ssh_key2.pem"
           }
       }, 
       {
           "main": {
               "host": "10.0.1.2", 
               "ssh_user": "ec2-user", 
               "ssh_private_key_file_path": "/home/ssh_key2.pem"
           }, 
           "dr": {
               "host": "10.2.1.2", 
               "ssh_user": "ec2-user", 
               "ssh_private_key_file_path": "/home/ssh_key2.pem".
               "ignore_healthcheck_warnings": true,
               "ingore_healthcheck_checks": ["cpu-count"]
           }
       }
   ]
   ```

2. Use an external tool to convert the JSON structures to a one-liner.
   
   For example:

   ```
   [{"main":{"host":"10.0.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"}},{"main":{"host":"10.0.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem","ignore_healthcheck_warnings":true,"ingore_healthcheck_checks":["cpu-count"]}}]
   ```
   
3. Wrap the JSON one-liner with single quotes (to avoid collision with the double quotes within the JSON structure) and use it
   to run the command. 

   A full command example - the example contains new lines to make it easier to read, when you run it, make sure to remove them and run
   this command in a **single line**:

   ```
   python3 -u -m upgrade.main 
       --agentless_gws '[{"main":{"host":"10.0.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"}},{"main":{"host":"10.0.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem","ignore_healthcheck_warnings":true,"ingore_healthcheck_checks":["cpu-count"]}}]' 
       --dsf_hubs '[{"main":{"host":"52.52.52.177","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"}}]' 
       --target_version "4.12.0.10.0"
   ```

4. By default, all upgrade stages run, if you want to change this, or change other configuration options, use the available arguments. 
   For example, if you want to see if you are ready to upgrade without upgrading yet, you can enable the "test connection" 
   and "preflight validations" stages and disable the "upgrade" and "postflight validations".
   
   For example:

   ```
   python3 -u -m upgrade.main 
       --agentless_gws '[{"main":{"host":"10.0.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.1","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"}},{"main":{"host":"10.0.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"},"dr":{"host":"10.2.1.2","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem","ignore_healthcheck_warnings":true,"ingore_healthcheck_checks":["cpu-count"]}}]' 
       --dsf_hubs '[{"main":{"host":"52.52.52.177","ssh_user":"ec2-user","ssh_private_key_file_path":"/home/ssh_key2.pem"}}]' 
       --target_version "4.12.0.10.0"
       --test_connection "true"
       --run_preflight_validations "true"
       --run_upgrade "false"
       --run_postflight_validations "false"
       --stop_on_failure "false"
       --tarball_location '{"s3_bucket": "myBucket", "s3_region": "us-east-1", "s3_key" = "prefix/jsonar-x.y.z.w.u.tar.gz"}'
   ``` 

## More Information

For information about the upgrade options, stages, validations, etc., refer to the Terraform module's [README](https://github.com/imperva/dsfkit/blob/master/modules/aws/sonar-upgrader/README.md).