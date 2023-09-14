# Sonar HADR Deployment example
[![GitHub tag](https://img.shields.io/github/v/tag/imperva/dsfkit.svg)](https://github.com/imperva/dsfkit/tags)

A DSF Hub and Agentless Gateway (formerly Sonar) deployment with Hub HADR and Agenless Gateway HADR.

This deployment consists of:

1. New VPC
2. One main DSF Hub
3. One DR DSF Hub
4. One main Agentless Gateway
5. One DR Agentless Gateway
6. DSF Hub HADR setup and Agenless Gateway HADR setup
7. Federation
8. Creation of a new “Demo DB” - RDS MySQL 
9. Auto configuration of the RDS MySQL to enable native audit 
10. Onboarding the DB to the Agentless Gateway
11. There is also an option to create an RDS MsSQL with audit configured and with synthetic data on it. In order to do so, use the variable 'db_types_to_onboard' and specify which DBs to create and onboard.<br/>
    For example, in order to create both 'RDS MySQL' and 'RDS MsSQL', run the following:
    ```bash
    terraform apply -auto-approve -var 'db_types_to_onboard=["RDS MySQL", "RDS MsSQL"]'
    ```
    For more details, go to the rds-mssql-db module.

## Default Example
```bash
terraform apply -auto-approve
```

## Customized Example
The default example contains variables with default values. In order to customize the variables, you can use the following for example:
```bash
terraform apply -auto-approve -var 'gw_count=2' -var 'vpc_ip_range="10.1.0.0/24"'
```
For a full list of this example's customization options which don't require code changes, refer to the [variables file](./variables.tf). Pay attention to the value type you are customizing.