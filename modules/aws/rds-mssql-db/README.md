# DSF RDS MsSQL
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

This Terraform module provisions an RDS MsSQL, configure audit on it using s3 bucket and generates synthetic data on it.
It should be used for poc / pov / lab purposes.

## Requirements
* Terraform v0.13 and up
* An AWS account
* Permissions to create RDS MsSQL, S3 bucket (for configuring the audit), and lambda (for generating data on the DB and running queried on it). Required permissions can be found [here](/permissions_samples/OnboardMssqlRdsWithDataPermissions.txt).

## Resources Provisioned
This Terraform module provisions several resources on AWS to create and onboard the RDS MsSQL with synthetic data on it. These resources include:
* A RDS MsSQL instance
* A security group to allow the required network access to and from the RDS MsSQL instance
* An IAM role with relevant policies attached to the RDS MsSQL and to the lambdas
* Two S3 buckets for configuring the audit on the RDS MsSQL and for running queries on the DB
* A VPC Endpoint in order that the lambda which exists in a vpc will have access to the created S3 bucket for running the queries
* Two Lambdas: 
  * Infra lambda that configuring which SQL queries types will be audited. In addition, it creates 4 DBs - finance, health, insurance, telecom - and generates 10,000 records to each one of the DBs.
  * Scheduled lambda which has 2 triggers:
    * Each 1 minute - run SQL queries on the DB for simulating general traffic, such as - create a table, insert into the table, select some records, create a user and grant select permissions, etc.
    * Each 10 minutes - run SQL queries on the DB for simulating suspicious activities, such as - failed logins, retrieve all the users and their rights, grant extensive permissions to a user, retrieve a large amount of data, etc.


## Inputs

The following input variables are **required**:

* `rds_subnet_ids`: List of subnet_ids to make RDS MsSQL available on 
* `security_group_ingress_cidrs`: List of allowed ingress cidr ranges for access to the RDS MsSQL

Refer to [variables.tf](variables.tf) for additional variables with default values and additional info

## Outputs

The following [outputs](outputs.tf) are exported:

* `db_username`: DB username
* `db_password`: DB password
* `db_name`: DB name
* `db_identifier`: DB identifier
* `db_endpoint`: DB endpoint, in order to connect to the DB if needed
* `db_arn`: DB ARN
* `db_engine`: DB engine
* `db_port`: DB port

## Usage

To use this module, add the following to your Terraform configuration:

```
provider "aws" {
}

module "globals" {
  source = "imperva/dsf-globals/aws"
}

module "rds_mssql" {
  source                       = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  rds_subnet_ids               = "${aws_subnet.example.id}"
  security_group_ingress_cidrs = "${aws_cidr.example}"
}
```

To see a complete example of how to use this module in a DSF deployment with other modules, check out the [examples](../../../examples/) directory.

We recommend using a specific version of the module (and not the latest).
See available released versions in the main repo README [here](https://github.com/imperva/dsfkit#version-history).

Specify the module's version by adding the version parameter. For example:

```
module "dsf_rds_mssql" {
  source  = "imperva/dsf-poc-db-onboarder/aws//modules/rds-mssql-db"
  version = "x.y.z"
}
```

## Additional Information

For additional information about DSF deployment using terraform, refer to the main repo README [here](https://github.com/imperva/dsfkit/tree/1.4.0).