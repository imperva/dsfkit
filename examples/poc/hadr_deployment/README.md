# HADR Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment with Hub HADR.

This deployment consists of:

1. New VPC
2. One Primary Hub
3. One Secondary Hub
4. One Gateway
5. Federation
6. Hub HADR
7. Creation of a new “Demo DB” - RDS MySQL
8. Auto configuration of the RDS MySQL to enable native audit
9. Onboard the DB to DSF Hub 
10. There is an option to create also a RDS MsSQL with audit configured and with synthetic data on it. In order to do so, use the variable 'db_types_to_onboard' and specify which DBs to create and onboard.
   For example, in order to create both 'RDS MySQL' and 'RDS MsSQL', run the following:
```bash
  terraform apply -auto-approve -var 'db_types_to_onboard=["RDS MySQL", "RDS MsSQL"]'
   ```
For more details, go to the rds-mssql-db module