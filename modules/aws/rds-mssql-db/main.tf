resource "random_password" "db_password" {
  length  = 15
  special = false
}

resource "random_pet" "db_id" {}

resource "random_id" "salt" {
  byte_length = 2
}

data "aws_region" "current" {}

locals {
  db_username           = var.username
  db_password           = length(var.password) > 0 ? var.password : random_password.db_password.result
  db_identifier         = length(var.identifier) > 0 ? var.identifier : join("-", [var.name_prefix, random_pet.db_id.id])
  db_name               = "master"
  mssql_connect_db_name = "rdsadmin"
  lambda_salt           = random_id.salt.hex
  db_audit_bucket_name  = "${local.db_identifier}-audit-bucket"
}

resource "aws_db_subnet_group" "rds_db_sg" {
  name       = "${local.db_identifier}-db-subnet-group"
  subnet_ids = var.rds_subnet_ids
  tags       = var.tags
}

resource "aws_s3_bucket" "rds_db_audit_bucket" {
  bucket        = local.db_audit_bucket_name
  force_destroy = true
  tags          = var.tags
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
  tags = var.tags
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
  tags                    = var.tags
}

data "aws_subnet" "subnet" {
  id = var.rds_subnet_ids[0]
}

resource "aws_security_group" "rds_mssql_access" {
  description = "RDS SQL Server Access"
  vpc_id      = data.aws_subnet.subnet.vpc_id
  tags        = var.tags
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

# copy the files from our s3 prod to the customer s3
data "aws_s3_objects" "source" {
  provider = aws.poc_scripts_s3_region
  bucket   = var.db_audit_scripts_bucket_name
}

data "aws_s3_object" "source" {
  provider = aws.poc_scripts_s3_region
  for_each = toset(data.aws_s3_objects.source.keys)

  bucket = data.aws_s3_objects.source.bucket
  key    = each.key
  tags   = var.tags
}

resource "aws_s3_bucket" "mssql_lambda_bucket" {
  bucket        = join("-", [var.name_prefix, "sql-scripts-bucket", local.lambda_salt])
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
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id            = data.aws_subnet.subnet.vpc_id
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.vpc_route_tables.ids
}

resource "aws_s3_object_copy" "s3_object_copy" {
  for_each = data.aws_s3_object.source

  bucket = aws_s3_bucket.mssql_lambda_bucket.bucket
  key    = each.value.key
  source = each.value.id
}

data "aws_s3_object" "mssql_lambda_package" {
  bucket = aws_s3_bucket.mssql_lambda_bucket.bucket
  key    = "mssqlLambdaPackage.zip"

  depends_on = [
    aws_s3_object_copy.s3_object_copy
  ]
}
