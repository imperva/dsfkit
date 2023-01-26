# Basic Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment.

This deployment consists of:

1. New VPC
2. One Hub
3. One Gateway
4. Federation
5. Creation of a new “Demo DB” - RDS MySQL
6. Auto configuration of the RDS MySQL to enable native audit
7. Onboard the DB to DSF Hub
8. There is an option to create also a RDS MsSQL with audit configured and with synthetic data on it. In order to do so, use the variable 'db_types_to_onboard' and specify which DBs to create and onboard.
For example, in order to create both 'RDS MySQL' and 'RDS MsSQL', run the following:
```bash
  terraform apply -auto-approve -var 'db_types_to_onboard=["RDS MySQL", "RDS MsSQL"]'
   ```
For more details, go to the rds-mssql-db module