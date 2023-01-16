resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_id" {
}

resource "random_id" "salt" {
  byte_length = 2
}

data "aws_region" "current" {}

locals {
  db_username                  = var.username
  db_password                  = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier                = length(var.identifier) > 0 ? var.identifier : "edsf-db-demo-${random_pet.db_id.id}"
  db_name                      = length(var.name) > 0 ? var.name : replace("edsf-db-demo-${random_pet.db_id.id}", "-", "_")
  cloudwatch_stream_names      = ["error"]
  mssql_connect_db_name        = "rdsadmin"
  lambda_salt                  = random_id.salt.hex
}


resource "aws_cloudwatch_log_group" "cloudwatch_streams" {
  for_each          = { for name in local.cloudwatch_stream_names : name => name }
  name              = "/aws/rds/instance/${local.db_identifier}/${each.value}"
  retention_in_days = 30
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
}

#resource "aws_db_option_group" "impv_rds_db_og" {
#  name                     = replace("${local.db_identifier}-pg", "_", "-")
#  option_group_description = "RDS DB option group"
#  engine_name              = "mysql"
#  major_engine_version     = "5.7"
#
#  option {
#    option_name = "MARIADB_AUDIT_PLUGIN"
#    option_settings {
#      name  = "SERVER_AUDIT_EVENTS"
#      value = "CONNECT,QUERY,QUERY_DDL,QUERY_DML,QUERY_DCL,QUERY_DML_NO_SELECT"
#    }
#    option_settings {
#      name  = "SERVER_AUDIT_EXCL_USERS"
#      value = "rdsadmin"
#    }
#  }
#}

# todo - should configure the audit by options groups / parameter groups for the MsSQL

/*
resource "aws_db_instance" "rds_db" {
  allocated_storage       = 20
#  db_name                 = local.db_name
  engine                  = "sqlserver-ex"
  engine_version          = "15.00.4236.7.v1"
  instance_class          = "db.t3.small"
  username                = local.db_username
  password                = local.db_password
#  option_group_name       = aws_db_option_group.impv_rds_db_og.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_mssql_access.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_db_sg.name
  identifier              = local.db_identifier
  publicly_accessible     = true
  backup_retention_period = 0

  enabled_cloudwatch_logs_exports = local.cloudwatch_stream_names
  depends_on = [
    aws_cloudwatch_log_group.cloudwatch_streams
  ]
}*/

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_mssql_access" {
  description = "RDS SQL Server Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id
}


#resource "aws_security_group_rule" "rds_mssql_access_rule" {
#  type              = "ingress"
#  from_port         = 1433
#  to_port           = 1433
#  protocol          = "tcp"
#  cidr_blocks       = var.security_group_ingress_cidrs
#  security_group_id = aws_security_group.rds_mssql_access.id
#}
#
#resource "aws_security_group_rule" "rds_mssql_sg_self" {
#  type              = "ingress"
#  from_port         = 0
#  to_port           = 0
#  protocol          = "-1"
#  self              = true
#  security_group_id = aws_security_group.rds_mssql_access.id
#}
#
#resource "aws_security_group_rule" "rds_mssql_all_out" {
#  type              = "egress"
#  from_port         = 0
#  to_port           = 0
#  protocol          = "-1"
#  cidr_blocks       = ["0.0.0.0/0"]
#  security_group_id = aws_security_group.rds_mssql_access.id
#}
#
## create the IS lambda and run it to create the DBs inside the MsSQL instance
#
#data "aws_iam_role" "lambda_mssql_assignee_role" {
#  name = split("/", local.role_arn)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
##  name = split("/", var.assignee_role)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
#}

# get the zip for lambda from s3


resource "aws_s3_bucket" "mssql_lambda_bucket" {
  bucket        = join("-", ["dsf-sql-scripts-bucket", local.lambda_salt])
  force_destroy = true
}

resource "null_resource" "mssql_s3_objects" {
  provisioner "local-exec" {
    // ae309159-115c-4504-b0c2-03dd022f3368
    command = "aws s3 cp s3://${var.db_audit_scripts_bucket_name} s3://${aws_s3_bucket.mssql_lambda_bucket.bucket} --recursive"
  }

  depends_on = [
    aws_s3_bucket.mssql_lambda_bucket
  ]
}

data "aws_route_tables" "vpc_route_tables" {
  vpc_id = data.aws_subnet.subnet.vpc_id
}

# verify it is ok and really needed
#resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
#  service_name = "com.amazonaws.${data.aws_region.current}.s3"
#  vpc_id       = data.aws_subnet.subnet.vpc_id
#  vpc_endpoint_type = "Gateway"
#  route_table_ids = [data.aws_route_tables.vpc_route_tables.ids]
#}


#data "aws_s3_object" "mssql_lambda_package" {
#  provider = aws.prod_s3_region
##  region = "us-east-1"
##  bucket = "arn:aws:s3:us-east-1:112114489393:ae309159-115c-4504-b0c2-03dd022f3368"
#  bucket = "hadar-mssql-us-east-1"
##  bucket = var.db_audit_scripts_bucket_name
##  bucket = "hadar-mssql"
#  key    = "task.zip"
#}

/*
resource "aws_lambda_function" "lambda_mssql_infra" {
#  function_name     = "dsf-mssql-infra"
  function_name     = join("-", ["dsf-mssql-infra", local.lambda_salt])
  s3_bucket         = data.aws_s3_object.mssql_lambda_package.bucket
  s3_key            = data.aws_s3_object.mssql_lambda_package.key
  s3_object_version = data.aws_s3_object.mssql_lambda_package.version_id
  role              = data.aws_iam_role.lambda_mssql_assignee_role.arn
#  role              = aws_iam_role.lambda_mssql_infra_role.arn
  handler           = "main.lambda_handler"
  runtime           = "python3.7"
  timeout           = 900

  vpc_config {
    security_group_ids = [aws_security_group.rds_mssql_access.id]
    subnet_ids         = var.rds_subnet_ids
  }

  environment {
    variables = {
      DB_URI  = aws_db_instance.rds_db.address
      DB_PORT = aws_db_instance.rds_db.port
      DB_NAME = local.mssql_connect_db_name
      DB_USER = aws_db_instance.rds_db.username
      DB_PWD  =  nonsensitive(aws_db_instance.rds_db.password)
    }
  }

  depends_on = [
    aws_db_instance.rds_db
  ]
}


# invoke the infra lambda once, to create the initial DBs
resource "aws_lambda_invocation" "mssql_infra_invocation" {
  function_name = aws_lambda_function.lambda_mssql_infra.function_name

  input = jsonencode({})
}

resource "aws_lambda_function" "lambda_mssql_scheduled" {
  function_name     = join("-", ["dsf-mssql-traffic-and-suspicious-activity", local.lambda_salt])
  s3_bucket         = data.aws_s3_object.mssql_lambda_package.bucket
  s3_key            = data.aws_s3_object.mssql_lambda_package.key
  s3_object_version = data.aws_s3_object.mssql_lambda_package.version_id
  role              = data.aws_iam_role.lambda_mssql_assignee_role.arn
  #  role              = aws_iam_role.lambda_mssql_infra_role.arn
  handler           = "appWorked.lambda_handler"
  runtime           = "python3.7"
  timeout           = 900

  vpc_config {
    security_group_ids = [aws_security_group.rds_mssql_access.id]
    subnet_ids         = var.rds_subnet_ids
  }

  environment {
    variables = {
      DB_URI    = aws_db_instance.rds_db.address
      DB_PORT   = aws_db_instance.rds_db.port
      DB_NAME   = local.mssql_connect_db_name
      DB_USER   = aws_db_instance.rds_db.username
      DB_PWD    = nonsensitive(aws_db_instance.rds_db.password)
      S3_BUCKET = data.aws_s3_object.mssql_lambda_package.bucket
    }
  }

  depends_on = [
    aws_db_instance.rds_db
  ]
}

# add scheduled events each 1 minute for the traffic queries
resource "aws_cloudwatch_event_rule" "trafficEachMinute" {
  name                = join("-", ["dsf-mssql-lambda-traffic-every-minute", local.lambda_salt])
  description         = "Schedule a lambda for DSF SQL Server that run traffic each 1 minute"
#  schedule_expression = "cron(0/1 * 1/1 * ? *)"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trafficEachMinuteTarget" {
  arn   = aws_lambda_function.lambda_mssql_scheduled.arn
  rule  = aws_cloudwatch_event_rule.trafficEachMinute.name
  input = "{\"S3_FILE_PREFIX\":\"mssql_traffic\"}"
}

resource "aws_lambda_permission" "allow_cloudwatchTraffic" {
  statement_id = "AllowTrafficExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_mssql_scheduled.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.trafficEachMinute.arn
}

# add scheduled events each 10 minutes for the suspicious activity queries
resource "aws_cloudwatch_event_rule" "suspiciousActivityEach10Minutes" {
  name                = join("-", ["dsf-mssql-lambda-suspicious-activity-every-10-minutes", local.lambda_salt])
  description         = "Schedule a lambda for DSF SQL Server that run suspicious activity each 10 minutes"
  #  schedule_expression = "cron(0/1 * 1/1 * ? *)"
  schedule_expression = "rate(10 minutes)"
}

resource "aws_cloudwatch_event_target" "suspiciousActivityEach10MinutesTarget" {
  arn  = aws_lambda_function.lambda_mssql_scheduled.arn
  rule = aws_cloudwatch_event_rule.suspiciousActivityEach10Minutes.name
  input = "{\"S3_FILE_PREFIX\":\"mssql_suspicious_activity\",\"SHOULD_RUN_FAILED_LOGINS\":\"true\",\"DBS_FAILED_LOGINS\":\"financedb;HealthCaredb;Insurancedb;telecomdb\",\"DB_USER2\":\"finance:Teller;health:public_health_nurse;insurance:Broker;telecom:Technician\"}"
}

resource "aws_lambda_permission" "allow_cloudwatchSuspicious" {
  statement_id = "AllowSuspiciousExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_mssql_scheduled.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.suspiciousActivityEach10Minutes.arn
}

# todo - maybe we have to add a wait of 1 minute before the schedule lambda so that the DBs will be exist for sure
#  or add depends on the end of the running
*/
