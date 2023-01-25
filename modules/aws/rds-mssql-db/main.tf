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
  mssql_connect_db_name        = "rdsadmin"
  lambda_salt                  = random_id.salt.hex
  lambda_package               = "${path.module}/installation_resources/mssqlLambdaPackage.zip"
  db_audit_bucket_name         = "${local.db_identifier}-audit-bucket"
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
}

resource "aws_s3_bucket" "rds_db_audit_bucket" {
  bucket        = local.db_audit_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "rds_db_audit_bucket_public_access_block" {
  bucket = aws_s3_bucket.rds_db_audit_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



resource "aws_db_option_group" "impv_rds_db_og" {
  name                     = replace("${local.db_identifier}-og", "_", "-")
  option_group_description = "RDS MSSQL DB option group"
  engine_name              = "sqlserver-ex"
  major_engine_version     = "15.00"

  option {
    option_name = "SQLSERVER_AUDIT"
    option_settings {
      name  = "ENABLE_COMPRESSION"
      value = "false"
    }
    option_settings {
      name  = "S3_BUCKET_ARN"
      value = aws_s3_bucket.rds_db_audit_bucket.arn
    }
    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds_db_og_role.arn
    }
    option_settings {
      name  = "RETENTION_TIME"
      value = "48"
    }
  }
}

resource "aws_db_instance" "rds_db" {
  allocated_storage       = 20
  engine                  = "sqlserver-ex"
  engine_version          = "15.00.4236.7.v1"
  instance_class          = "db.t3.small"
  username                = local.db_username
  password                = local.db_password
  option_group_name       = aws_db_option_group.impv_rds_db_og.name
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_mssql_access.id]
  db_subnet_group_name    = aws_db_subnet_group.rds_db_sg.name
  identifier              = local.db_identifier
  publicly_accessible     = true
  backup_retention_period = 0
}

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_mssql_access" {
  description = "RDS SQL Server Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id
}

resource "aws_security_group_rule" "rds_mssql_access_rule" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  cidr_blocks       = var.security_group_ingress_cidrs
  security_group_id = aws_security_group.rds_mssql_access.id
}

resource "aws_security_group_rule" "rds_mssql_sg_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.rds_mssql_access.id
}

resource "aws_security_group_rule" "rds_mssql_all_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds_mssql_access.id
}

# create the IS lambda and run it to create the DBs inside the MsSQL instance
data "aws_iam_role" "lambda_mssql_assignee_role" {
  name = split("/", local.role_arn)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_lambda_function" "lambda_mssql_infra" {
  function_name     = join("-", ["dsf-mssql-infra", local.lambda_salt])
  filename          = local.lambda_package
  role              = data.aws_iam_role.lambda_mssql_assignee_role.arn
  handler           = "createDBsAndEnableAudit.lambda_handler"
  runtime           = "python3.9"
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

# create a s3 bucket and upload the mssql files to it , and then update the role to take a look to it.
resource "aws_s3_bucket" "mssql_lambda_bucket" {
  bucket        = join("-", ["dsf-sql-scripts-bucket", local.lambda_salt])
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.mssql_lambda_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# create a vpc endpoint so that the lambda can access to s3. lambda is with the vpc of the installation deployment,
# so it is necessary to use this
data "aws_route_tables" "vpc_route_tables" {
  vpc_id = data.aws_subnet.subnet.vpc_id
}

resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id       = data.aws_subnet.subnet.vpc_id
  vpc_endpoint_type = "Gateway"
  route_table_ids = data.aws_route_tables.vpc_route_tables.ids
}

resource "aws_s3_object" "mssql_lambda_objects" {
  for_each      = fileset("${path.module}/installation_resources/", "**")
  bucket        = aws_s3_bucket.mssql_lambda_bucket.id
  key           = each.value
  source        = "${path.module}/installation_resources/${each.value}"
  etag          = filemd5("${path.module}/installation_resources/${each.value}")
  force_destroy = true
}

data "aws_s3_object" "mssql_lambda_package" {
  bucket = aws_s3_bucket.mssql_lambda_bucket.bucket
  key    = "mssqlLambdaPackage.zip"

  depends_on = [
    aws_s3_object.mssql_lambda_objects
  ]
}

resource "aws_lambda_function" "lambda_mssql_scheduled" {
  function_name     = join("-", ["dsf-mssql-traffic-and-suspicious-activity", local.lambda_salt])
  s3_bucket         = data.aws_s3_object.mssql_lambda_package.bucket
  s3_key            = data.aws_s3_object.mssql_lambda_package.key
  s3_object_version = data.aws_s3_object.mssql_lambda_package.version_id
  role              = data.aws_iam_role.lambda_mssql_assignee_role.arn
  handler           = "trafficAndSuspiciousQueries.lambda_handler"
  runtime           = "python3.9"
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
      S3_BUCKET = aws_s3_bucket.mssql_lambda_bucket.bucket
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
