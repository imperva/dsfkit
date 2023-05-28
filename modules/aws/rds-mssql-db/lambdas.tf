# create the IS lambda and run it to create the DBs inside the MsSQL instance
data "aws_iam_role" "lambda_mssql_assignee_role" {
  name = split("/", local.role_arn)[1] //arn:aws:iam::xxxxxxxxx:role/role-name
}

resource "aws_lambda_function" "lambda_mssql_infra" {
  function_name     = join("-", ["dsf-mssql-infra", local.lambda_salt])
  s3_bucket         = data.aws_s3_object.mssql_lambda_package.bucket
  s3_key            = data.aws_s3_object.mssql_lambda_package.key
  s3_object_version = data.aws_s3_object.mssql_lambda_package.version_id
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
      DB_PWD  = nonsensitive(aws_db_instance.rds_db.password)
    }
  }

  tags = var.tags
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

  tags = var.tags
  depends_on = [
    aws_db_instance.rds_db
  ]
}

# add scheduled events each 1 minute for the traffic queries
resource "aws_cloudwatch_event_rule" "trafficEachMinute" {
  name                = join("-", ["dsf-mssql-lambda-traffic-every-minute", local.lambda_salt])
  description         = "Schedule a lambda for DSF SQL Server that run traffic each 1 minute"
  schedule_expression = "rate(1 minute)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "trafficEachMinuteTarget" {
  arn   = aws_lambda_function.lambda_mssql_scheduled.arn
  rule  = aws_cloudwatch_event_rule.trafficEachMinute.name
  input = "{\"S3_FILE_PREFIX\":\"mssql_traffic\"}"
}

resource "aws_lambda_permission" "allow_cloudwatchTraffic" {
  statement_id  = "AllowTrafficExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_mssql_scheduled.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.trafficEachMinute.arn
}

# add scheduled events each 10 minutes for the suspicious activity queries
resource "aws_cloudwatch_event_rule" "suspiciousActivityEach10Minutes" {
  name                = join("-", ["dsf-mssql-lambda-suspicious-activity-every-10-minutes", local.lambda_salt])
  description         = "Schedule a lambda for DSF SQL Server that run suspicious activity each 10 minutes"
  schedule_expression = "rate(10 minutes)"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "suspiciousActivityEach10MinutesTarget" {
  arn   = aws_lambda_function.lambda_mssql_scheduled.arn
  rule  = aws_cloudwatch_event_rule.suspiciousActivityEach10Minutes.name
  input = "{\"S3_FILE_PREFIX\":\"mssql_suspicious_activity\",\"SHOULD_RUN_FAILED_LOGINS\":\"true\",\"DBS_FAILED_LOGINS\":\"financedb;HealthCaredb;Insurancedb;telecomdb\",\"DB_USER2\":\"finance:Teller;health:public_health_nurse;insurance:Broker;telecom:Technician\"}"
}

resource "aws_lambda_permission" "allow_cloudwatchSuspicious" {
  statement_id  = "AllowSuspiciousExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_mssql_scheduled.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.suspiciousActivityEach10Minutes.arn
}
